import AppKit
import ApplicationServices
import Foundation

/// Step-1 prototype for the Finder hjkl drill. AppleScript stripped
/// out for now — the first priority is confirming the AX readback is
/// reliable in isolation. Layout forcing (icon view, grid, window
/// size) will come back in a later step behind a background queue
/// with a hard timeout.
///
/// Moving parts verified by this step:
///   1. Materialize a tmp folder with N .txt files.
///   2. Tag one of them "Red" so Finder shows it in a different color.
///   3. Open the folder in Finder.
///   4. Read back the Finder window's `AXSelectedChildren` via the
///      Accessibility API.
///
/// Everything logs to AppLogger so you can tail the log.
enum FinderDrillPrototype {
    struct Result {
        var folder: URL
        var files: [URL]
        var target: URL
        var start: URL
        var selectionReadback: String
    }

    @discardableResult
    static func run(rows: Int = 3, cols: Int = 4) async -> Result? {
        let log = AppLogger.shared
        log.info("finderDrill", "start", fields: ["rows": "\(rows)", "cols": "\(cols)"])

        // Sweep any leftover drill state from prior runs so the new
        // drill is the only one onscreen and on disk.
        await MainActor.run { closeLeftoverDrillWindows() }
        removeLeftoverDrillFolders()

        guard let (folder, files) = makeTempFolder(count: rows * cols) else {
            log.info("finderDrill", "tempFolderFailed", fields: [:])
            return nil
        }

        let target = files[files.count - 1]
        let start = files[0]
        tagURL(target, with: "Red")

        NSWorkspace.shared.open(folder)
        try? await Task.sleep(for: .milliseconds(700))
        activateFinderAndSwitchToIconView()
        try? await Task.sleep(for: .milliseconds(300))
        await MainActor.run { moveFinderWindowToLeft() }
        try? await Task.sleep(for: .milliseconds(200))
        // Clear the seed tag — the engine will re-tag the active rep's
        // target each time so the red dot always reflects the goal.
        tagURL(target, with: nil)

        let readback = readFinderSelection() ?? "<no selection read>"
        log.info("finderDrill", "axSelection", fields: ["value": readback])

        return Result(
            folder: folder,
            files: files,
            target: target,
            start: start,
            selectionReadback: readback
        )
    }

    /// Prompts for Accessibility if not trusted. Separate from `run()`
    /// so the prompt sheet can't race with the rest of the flow — the
    /// user grants permission, then re-invokes the drill.
    @discardableResult
    static func requestAccessibility() -> Bool {
        let opts: CFDictionary = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(opts)
        AppLogger.shared.info("finderDrill", "axTrustCheck",
                              fields: ["trusted": trusted ? "yes" : "no"])
        return trusted
    }

    static func cleanUp(_ folder: URL) {
        try? FileManager.default.removeItem(at: folder)
    }

    // MARK: - Singleton enforcement

    /// Close any Finder windows whose title starts with our tmp
    /// folder prefix. Uses AX only (no AppleScript / Automation
    /// permission).
    @MainActor
    private static func closeLeftoverDrillWindows() {
        guard let finder = NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.apple.finder"
        ).first else { return }
        let app = AXUIElementCreateApplication(finder.processIdentifier)
        var windowsRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            app, kAXWindowsAttribute as CFString, &windowsRef
        ) == .success,
              let windows = windowsRef as? [AXUIElement] else { return }

        for window in windows {
            var titleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
            var docRef: CFTypeRef?
            AXUIElementCopyAttributeValue(window, kAXDocumentAttribute as CFString, &docRef)
            let title = (titleRef as? String) ?? ""
            let doc = (docRef as? String) ?? ""
            guard title.contains("kindaVimTutorFinder") ||
                  doc.contains("kindaVimTutorFinder") else { continue }
            var closeRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(
                window, kAXCloseButtonAttribute as CFString, &closeRef
            ) == .success, let closeRef {
                AXUIElementPerformAction(
                    closeRef as! AXUIElement, kAXPressAction as CFString
                )
            }
        }
    }

    /// Delete any leftover `kindaVimTutorFinder-*` directories in the
    /// temporary directory. Covers prior runs that crashed or were
    /// killed before the end-of-drill cleanup ran.
    private static func removeLeftoverDrillFolders() {
        let fm = FileManager.default
        let tmp = fm.temporaryDirectory
        guard let entries = try? fm.contentsOfDirectory(
            at: tmp, includingPropertiesForKeys: nil
        ) else { return }
        for url in entries
            where url.lastPathComponent.hasPrefix("kindaVimTutorFinder-") {
            try? fm.removeItem(at: url)
        }
    }

    // MARK: - Filesystem

    private static func makeTempFolder(count: Int) -> (URL, [URL])? {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("kindaVimTutorFinder-\(UUID().uuidString.prefix(8))",
                                    isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: tmp,
                                                    withIntermediateDirectories: true)
        } catch {
            return nil
        }
        var urls: [URL] = []
        for i in 0..<count {
            let name = String(format: "file%02d.txt", i + 1)
            let url = tmp.appendingPathComponent(name)
            FileManager.default.createFile(atPath: url.path, contents: Data())
            urls.append(url)
        }
        return (tmp, urls)
    }

    /// Sets (or clears, when `tag == nil`) the given Finder tag on a
    /// URL. Exposed internal so the engine can re-tag the active rep's
    /// target between reps.
    static func tagURL(_ url: URL, with tag: String?) {
        do {
            let value: NSArray = tag.map { [$0] as NSArray } ?? []
            try (url as NSURL).setResourceValue(value, forKey: .tagNamesKey)
        } catch {
            AppLogger.shared.info("finderDrill", "tagFailed",
                                  fields: ["err": "\(error)"])
        }
    }

    // MARK: - Layout

    /// Moves (without resizing) the focused Finder window to the
    /// left side of the main screen. We don't set size because
    /// Finder's icon view doesn't reflow on resize — clipping icons
    /// if we shrink it. The coaching panel positions itself to the
    /// right of wherever Finder ended up.
    @MainActor
    private static func moveFinderWindowToLeft() {
        guard let screen = NSScreen.main else { return }
        let axY = screen.frame.maxY - screen.visibleFrame.maxY + 40
        let origin = CGPoint(x: screen.visibleFrame.minX + 40, y: axY)
        FinderGrid.moveFocusedFinderWindow(to: origin)
    }

    // MARK: - View mode

    /// Bring Finder frontmost and post ⌘1 so its window switches to
    /// icon view. Chosen over AppleScript (which hung us earlier) and
    /// over `.DS_Store` manipulation (unreliable — Finder caches its
    /// own view state in memory per-window).
    private static func activateFinderAndSwitchToIconView() {
        guard let finder = NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.apple.finder"
        ).first else { return }
        finder.activate(options: [.activateAllWindows])

        // Give the activation a beat so the keystroke lands in the
        // right app.
        Thread.sleep(forTimeInterval: 0.15)

        let src = CGEventSource(stateID: .hidSystemState)
        let keyCode: CGKeyCode = 0x12 // kVK_ANSI_1
        let down = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true)
        let up   = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false)
        down?.flags = .maskCommand
        up?.flags   = .maskCommand
        down?.postToPid(finder.processIdentifier)
        up?.postToPid(finder.processIdentifier)
    }

    // MARK: - AX readback

    /// Reads the filename(s) of the currently selected file(s) in the
    /// frontmost Finder window. Walks the window's accessibility tree
    /// looking for a container that exposes `AXSelectedRows` (list /
    /// column view) or `AXSelectedChildren` (icon view), then
    /// recovers the filename from each selected element.
    static func readFinderSelection() -> String? {
        guard let finder = NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.apple.finder"
        ).first else { return nil }
        let app = AXUIElementCreateApplication(finder.processIdentifier)

        var focusedWindow: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            app, kAXFocusedWindowAttribute as CFString, &focusedWindow
        ) == .success, let focusedWindow else { return nil }

        return findSelection(in: focusedWindow as! AXUIElement, depth: 0)
    }

    private static func findSelection(in element: AXUIElement, depth: Int) -> String? {
        guard depth < 10 else { return nil }

        // List/column view: AXSelectedRows (array of AXRow).
        if let names = arrayAttribute(element, "AXSelectedRows")
            .flatMap({ collectNames($0) }) {
            return names
        }
        // Icon view: AXSelectedChildren.
        if let names = arrayAttribute(element, kAXSelectedChildrenAttribute as String)
            .flatMap({ collectNames($0) }) {
            return names
        }

        guard let kids = arrayAttribute(element, kAXChildrenAttribute as String) else {
            return nil
        }
        for kid in kids {
            if let found = findSelection(in: kid, depth: depth + 1) {
                return found
            }
        }
        return nil
    }

    /// Resolve a display name for each selected element. For list-view
    /// rows the filename lives in a descendant static-text child;
    /// `recoverName` digs until it finds one.
    private static func collectNames(_ arr: [AXUIElement]) -> String? {
        guard !arr.isEmpty else { return nil }
        let names = arr.compactMap { recoverName($0, depth: 0) }
        return names.isEmpty ? nil : names.joined(separator: ", ")
    }

    private static func recoverName(_ element: AXUIElement, depth: Int) -> String? {
        guard depth < 6 else { return nil }
        for attr in [kAXTitleAttribute, kAXDescriptionAttribute, kAXValueAttribute] {
            var v: CFTypeRef?
            if AXUIElementCopyAttributeValue(element, attr as CFString, &v) == .success,
               let s = v as? String, !s.isEmpty {
                return s
            }
        }
        guard let kids = arrayAttribute(element, kAXChildrenAttribute as String) else {
            return nil
        }
        for kid in kids {
            if let s = recoverName(kid, depth: depth + 1) { return s }
        }
        return nil
    }

    private static func arrayAttribute(_ element: AXUIElement, _ name: String) -> [AXUIElement]? {
        var v: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &v) == .success,
              let arr = v as? [AXUIElement] else { return nil }
        return arr
    }
}
