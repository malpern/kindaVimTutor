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
///   1. Materialize a tmp folder with N subfolders + custom icons.
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
    static func run(names: [String],
                    rows: Int = 3,
                    cols: Int = 4) async -> Result? {
        let log = AppLogger.shared
        log.info("finderDrill", "start", fields: ["rows": "\(rows)", "cols": "\(cols)"])

        await MainActor.run { closeLeftoverDrillWindows() }

        // Run the expensive filesystem work off the main thread so
        // the UI doesn't beachball for ~20+s while we create 12
        // subfolders and write 12 custom icons each. macOS's
        // NSWorkspace.setIcon + the Icon\r file writes are slow
        // enough in aggregate that this matters a lot.
        let built = await Task.detached(priority: .userInitiated) {
            () -> (URL, [URL])? in
            removeLeftoverDrillFolders()
            return makeTempFolder(names: names)
        }.value

        guard let (folder, files) = built else {
            log.info("finderDrill", "tempFolderFailed", fields: [:])
            return nil
        }
        log.info("finderDrill", "tempFolderReady",
                 fields: ["path": folder.lastPathComponent])

        let target = files.last!
        let start = files.first!

        NSWorkspace.shared.open(folder)
        try? await Task.sleep(for: .milliseconds(700))
        await MainActor.run { activateFinderAndSwitchToIconView() }
        try? await Task.sleep(for: .milliseconds(300))
        await MainActor.run { moveFinderWindowToLeft() }
        try? await Task.sleep(for: .milliseconds(200))

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

    // MARK: - Random naming

    private static let regularNamePool: [String] = [
        "notes", "drafts", "photos", "music", "docs", "ideas",
        "taxes", "recipes", "books", "plans", "scraps", "journal",
        "letters", "sketches", "receipts", "memes", "bookmarks",
        "ephemera", "clippings", "fragments", "backups", "misc",
        "postcards", "snippets", "mixtapes"
    ]

    private static let targetNamePool: [String] = [
        "TREASURE", "GOAL", "PRIZE", "GOLD", "FINISH",
        "WINNER", "BULLSEYE", "HOME", "VICTORY", "JACKPOT"
    ]

    /// Returns `count` random lowercase names — one per grid slot.
    /// No ALL-CAPS here; the engine renames the current rep's
    /// target folder to an ALL-CAPS name at rep start and restores
    /// it on advance, so only the active goal is SHOUTING.
    static func generateFolderNames(count: Int,
                                    targetIndices: Set<Int>) -> [String] {
        let shuffled = regularNamePool.shuffled()
        var out: [String] = []
        out.reserveCapacity(count)
        for i in 0..<count {
            out.append(i < shuffled.count ? shuffled[i] : "folder\(i + 1)")
        }
        return out
    }

    /// Returns a random unused ALL-CAPS target name — callers pass
    /// the set of names already used in the current drill to avoid
    /// repeats across reps.
    static func randomTargetName(excluding used: Set<String>) -> String {
        let pool = targetNamePool.shuffled()
        return pool.first(where: { !used.contains($0) }) ?? "TARGET"
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

    private static func makeTempFolder(names: [String]) -> (URL, [URL])? {
        let fm = FileManager.default
        let tmp = fm.temporaryDirectory
            .appendingPathComponent("kindaVimTutorFinder-\(UUID().uuidString.prefix(8))",
                                    isDirectory: true)
        do {
            try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
        } catch {
            return nil
        }
        var urls: [URL] = []
        for name in names {
            let sub = tmp.appendingPathComponent(name, isDirectory: true)
            do {
                try fm.createDirectory(at: sub, withIntermediateDirectories: false)
                urls.append(sub)
            } catch {
                AppLogger.shared.info("finderDrill", "createFolderFailed",
                                      fields: ["name": name, "err": "\(error)"])
            }
            // Non-targets all wear the same muted neutral folder so
            // the target is the only color in the grid. Target icons
            // are applied per-rep by the engine (different vivid
            // color each time), so at creation we just seed every
            // slot with the neutral.
            if let neutral = loadIconImage(named: "furry-neutral") {
                NSWorkspace.shared.setIcon(neutral, forFile: sub.path, options: [])
            }
        }
        return (tmp, urls)
    }

    // MARK: - Folder icons

    // MARK: - Target icon swap (per rep)

    /// The key used for the closed-treasure-chest folder icon —
    /// applied to the current rep's target so it reads as "the
    /// treasure" against the neutral-furry crowd. Sits in a
    /// different Resources subdirectory than the furry folders.
    static let targetIconKey = "chest-closed"

    /// Retained for earlier per-rep-color iterations. Not used by
    /// the current drill but left in place in case future drills
    /// want vivid-colored targets back.
    static let targetIconKeys: [String] = [
        "furry-target-magenta",
        "furry-target-gold",
        "furry-target-cyan",
        "furry-target-lime",
        "furry-target-orange",
        "furry-target-violet",
    ]

    /// Approximate display color for a target icon key. Used by the
    /// coaching panel to tint the target name and accent dots to
    /// match the folder's color.
    static func approximateColor(forIconKey key: String) -> (r: Double, g: Double, b: Double) {
        switch key {
        case "furry-target-magenta": return (0.96, 0.10, 0.70)
        case "furry-target-gold":    return (0.97, 0.76, 0.10)
        case "furry-target-cyan":    return (0.10, 0.80, 0.92)
        case "furry-target-lime":    return (0.55, 0.88, 0.18)
        case "furry-target-orange":  return (0.99, 0.55, 0.10)
        case "furry-target-violet":  return (0.60, 0.30, 0.96)
        default:                      return (0.96, 0.10, 0.70)
        }
    }

    /// Rename `from` → `to` and apply `iconKey` in one pass. The
    /// rename triggers a Finder refresh that also forces the new
    /// icon to show without an aggressive cache flush. Returns the
    /// new URL, or nil on failure.
    @discardableResult
    static func renameAndSetIcon(from: URL, to newName: String, iconKey: String) -> URL? {
        let parent = from.deletingLastPathComponent()
        let newURL = parent.appendingPathComponent(newName, isDirectory: true)
        if from != newURL {
            do {
                try FileManager.default.moveItem(at: from, to: newURL)
            } catch {
                AppLogger.shared.info("finderDrill", "renameFailed", fields: [
                    "from": from.lastPathComponent,
                    "to": newName,
                    "err": "\(error)"
                ])
                return nil
            }
        }
        setTargetIcon(on: newURL, key: iconKey)
        return newURL
    }

    /// Applies the given vivid icon to `folder`. Pass `nil` to
    /// restore the neutral icon.
    static func setTargetIcon(on folder: URL, key: String?) {
        let loadKey = key ?? "furry-neutral"
        guard let image = loadIconImage(named: loadKey) else {
            AppLogger.shared.info("finderDrill", "iconLoadFailed",
                                  fields: ["key": loadKey])
            return
        }
        let ok = NSWorkspace.shared.setIcon(image, forFile: folder.path, options: [])
        AppLogger.shared.info("finderDrill", "iconSet",
                              fields: [
                                "key": loadKey,
                                "folder": folder.lastPathComponent,
                                "ok": ok ? "yes" : "no"
                              ])
        // Finder caches icons aggressively — especially after a
        // rename, where it latches onto the default system folder
        // icon and ignores the xattr we just wrote. Force a visible
        // refresh by toggling the custom-icon bit off + back on,
        // and touching the folder's mtime so Finder re-reads it.
        NSWorkspace.shared.setIcon(nil, forFile: folder.path, options: [])
        NSWorkspace.shared.setIcon(image, forFile: folder.path, options: [])
        try? FileManager.default.setAttributes(
            [.modificationDate: Date()], ofItemAtPath: folder.path
        )
        try? FileManager.default.setAttributes(
            [.modificationDate: Date()],
            ofItemAtPath: folder.deletingLastPathComponent().path
        )
    }

    /// The 12 base color keys in stable order. Names matched to the
    /// assets bundled under Resources/furry-folders.
    private static let baseIconKeys: [String] = [
        "furry-01-coral",
        "furry-02-peach",
        "furry-03-butter",
        "furry-04-mint",
        "furry-05-sky",
        "furry-06-lavender",
        "furry-07-rose",
        "furry-08-teal",
        "furry-09-sage",
        "furry-10-cream",
        "furry-11-denim",
        "furry-12-taupe",
    ]

    static func baseIconKey(index: Int) -> String {
        baseIconKeys[index % baseIconKeys.count]
    }

    private static func loadIconImage(named key: String) -> NSImage? {
        // Bundled via .process("Resources"). SwiftPM may preserve
        // subdirectory layout in the top-level bundle but flatten
        // it inside the generated resource bundle. Try each known
        // subdirectory + the root fallback.
        let candidates: [String?] = ["furry-folders", "treasure", nil]
        for sub in candidates {
            if let url = Bundle.module.url(
                forResource: key, withExtension: "png", subdirectory: sub
            ) {
                if let image = NSImage(contentsOf: url) { return image }
            }
        }
        return nil
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

        // Schedule the ⌘1 keystroke a beat after activation so it
        // lands in Finder. Scheduling asynchronously avoids
        // blocking the main thread with Thread.sleep.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let src = CGEventSource(stateID: .hidSystemState)
            let keyCode: CGKeyCode = 0x12 // kVK_ANSI_1
            let down = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true)
            let up   = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false)
            down?.flags = .maskCommand
            up?.flags   = .maskCommand
            down?.postToPid(finder.processIdentifier)
            up?.postToPid(finder.processIdentifier)
        }
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
