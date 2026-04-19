import SwiftUI
import AppKit

@Observable
@MainActor
final class ModeMonitor {
    private(set) var currentMode: VimMode = .unknown
    private(set) var isKindaVimRunning: Bool = false

    // Two watchers:
    //   dirSource  — fires on atomic replaces (rename-in-place), the file
    //                itself gets a fresh inode so a file-level FD would
    //                immediately go stale.
    //   fileSource — fires on in-place writes (truncate + write), the dir
    //                contents don't change so a directory-level watcher
    //                wouldn't see it.
    // We install both and de-dupe via `readEnvironment()`'s "only notify on
    // actual change" guard. This covers every write pattern kindaVim could
    // use and lands within tens of ms of the write on APFS.
    private var dirSource: DispatchSourceFileSystemObject?
    private var dirFD: Int32 = -1
    private var fileSource: DispatchSourceFileSystemObject?
    private var fileFD: Int32 = -1
    private var pollTimer: Timer?

    /// kindaVim writes its current mode to this file whenever state changes.
    /// See https://docs.kindavim.app/integrations/json-file
    private var environmentFileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                             in: .userDomainMask).first!
        return base.appendingPathComponent("kindaVim/environment.json")
    }

    func startMonitoring() {
        checkKindaVimRunning()
        readEnvironment()
        installDirectoryWatcher()
        installFileWatcher()
        // Safety-net poll. With both kernel-event sources above we almost
        // never need this, but exotic filesystems (SMB, iCloud Drive) can
        // surface events inconsistently — 500ms keeps the worst-case visible
        // latency bounded without burning real CPU on a 17-byte file.
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkKindaVimRunning()
                self?.readEnvironment()
            }
        }
        AppLogger.shared.info("modeMonitor", "startMonitoring", fields: [
            "running": isKindaVimRunning ? "1" : "0",
            "mode": String(describing: currentMode),
            "envFile": environmentFileURL.path,
        ])
    }

    func stopMonitoring() {
        pollTimer?.invalidate()
        pollTimer = nil
        dirSource?.cancel()
        dirSource = nil
        fileSource?.cancel()
        fileSource = nil
        if dirFD >= 0 { close(dirFD); dirFD = -1 }
        if fileFD >= 0 { close(fileFD); fileFD = -1 }
    }

    func checkKindaVimRunning() {
        let bundleIds = [
            "mo.com.sleeplessmind.kindaVim",
            "app.kindavim.kindaVim",
            "com.godbout.kindaVim",
        ]
        isKindaVimRunning = bundleIds.contains { id in
            !NSRunningApplication.runningApplications(withBundleIdentifier: id).isEmpty
        }
    }

    // MARK: - environment.json

    private func readEnvironment() {
        let url = environmentFileURL
        guard let data = try? Data(contentsOf: url),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let modeString = raw["mode"] as? String else {
            // File missing, unreadable, or mode key absent — leave state alone.
            return
        }
        let newMode = Self.parseMode(modeString)
        if newMode != currentMode {
            AppLogger.shared.info("modeMonitor", "modeChanged", fields: [
                "from": String(describing: currentMode),
                "to": String(describing: newMode),
                "raw": modeString,
            ])
            currentMode = newMode
        }
    }

    private static func parseMode(_ raw: String) -> VimMode {
        // kindaVim's JSON uses lowercase enum-name strings. Handle common
        // variants defensively.
        switch raw.lowercased() {
        case "normal":                    return .normal
        case "insert":                    return .insert
        case "visual":                    return .visual
        case "operatorpending",
             "operator_pending",
             "operator-pending":          return .normal   // treat pending as normal
        default:                          return .unknown
        }
    }

    // MARK: - watchers

    private func installDirectoryWatcher() {
        let dir = environmentFileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let fd = open(dir.path, O_EVTONLY)
        guard fd >= 0 else {
            AppLogger.shared.error("modeMonitor", "dirOpenFailed", fields: [
                "path": dir.path,
                "errno": String(errno),
            ])
            return
        }
        dirFD = fd

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .rename, .delete],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            // A directory event usually means the file was atomically
            // replaced — our file-level FD now points at the old inode.
            // Re-open it against the new one.
            self?.reinstallFileWatcher()
            self?.readEnvironment()
        }
        source.setCancelHandler { [weak self] in
            guard let self else { return }
            if self.dirFD >= 0 { close(self.dirFD); self.dirFD = -1 }
        }
        source.resume()
        dirSource = source
    }

    /// File-level watcher. Only useful while `environmentFileURL` exists
    /// and refers to a live inode. Caller must re-install after the file
    /// is replaced on disk (via `reinstallFileWatcher`).
    private func installFileWatcher() {
        let path = environmentFileURL.path
        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else {
            // File doesn't exist yet — the directory watcher will pick up
            // its creation; we'll install the file watcher then.
            return
        }
        fileFD = fd

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .attrib, .delete, .rename],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            self?.readEnvironment()
        }
        source.setCancelHandler { [weak self] in
            guard let self else { return }
            if self.fileFD >= 0 { close(self.fileFD); self.fileFD = -1 }
        }
        source.resume()
        fileSource = source
    }

    private func reinstallFileWatcher() {
        fileSource?.cancel()
        fileSource = nil
        // cancelHandler closes fileFD.
        installFileWatcher()
    }
}
