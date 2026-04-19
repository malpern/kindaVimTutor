import SwiftUI
import AppKit

@Observable
@MainActor
final class ModeMonitor {
    private(set) var currentMode: VimMode = .unknown
    private(set) var isKindaVimRunning: Bool = false

    private var dirSource: DispatchSourceFileSystemObject?
    private var dirFD: Int32 = -1
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
        // Safety-net poll every 1.5s in case the dir watcher misses an event
        // (e.g. atomic replace on a filesystem that doesn't surface vnode
        // events consistently). Cheap.
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
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
        if dirFD >= 0 { close(dirFD); dirFD = -1 }
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

    private func installDirectoryWatcher() {
        // Watch the parent directory so atomic replaces (rename-in-place)
        // still trigger an event. The file itself may be recreated on each
        // write, in which case an FD on the file goes stale immediately.
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
            self?.readEnvironment()
        }
        source.setCancelHandler { [weak self] in
            guard let self else { return }
            if self.dirFD >= 0 { close(self.dirFD); self.dirFD = -1 }
        }
        source.resume()
        dirSource = source
    }
}
