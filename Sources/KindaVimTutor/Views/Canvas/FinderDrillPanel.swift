import AppKit
import SwiftUI

/// A borderless, non-activating NSPanel that floats above Finder
/// during a Finder-navigation drill. Hosts `FinderDrillCoachingView`
/// and observes the engine's state.
///
/// Key settings:
///   - `.floatingPanel` style mask: no title bar, borderless-looking.
///   - `level = .floating`: stays above regular windows.
///   - `becomesKeyOnlyIfNeeded = true` + `hidesOnDeactivate = false`:
///     Finder keeps keyboard focus while the panel is visible, so
///     hjkl still routes to Finder's icon view.
///   - `collectionBehavior = [.canJoinAllSpaces, .transient]`: the
///     panel follows the user across Spaces without showing in the
///     app switcher.
@MainActor
final class FinderDrillPanel {
    static let shared = FinderDrillPanel()

    private var panel: NSPanel?
    private var activationObserver: NSObjectProtocol?

    func show(engine: FinderDrillEngine, modeMonitor: ModeMonitor) {
        if let panel {
            panel.orderFrontRegardless()
            return
        }

        let view = FinderDrillCoachingView(engine: engine, modeMonitor: modeMonitor)
        let hosting = NSHostingController(rootView: view)
        hosting.view.setFrameSize(NSSize(width: 360, height: 170))
        // The hosting controller's backing NSView defaults to opaque
        // with a system background color; that's what was painting the
        // grey rectangular frame visible *behind* the SwiftUI rounded
        // card. Clear it so only the card's own shape shows.
        hosting.view.wantsLayer = true
        hosting.view.layer?.backgroundColor = .clear

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 170),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.worksWhenModal = true
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
        panel.contentViewController = hosting
        panel.backgroundColor = .clear
        panel.isOpaque = false
        // Let SwiftUI draw the shadow on the rounded content — the
        // system-drawn NSWindow shadow would trace the rectangular
        // window frame instead of the rounded card, producing the
        // outline artifact we saw around the corners.
        panel.hasShadow = false

        positionPanel(panel)

        panel.orderFrontRegardless()
        self.panel = panel
        installFinderActivationWatcher()
    }

    /// Keep the panel visible only while Finder is the frontmost app.
    /// When the student alt-tabs to another window — chat, browser —
    /// the floating panel would otherwise sit on top and nag them.
    /// Observes NSWorkspace and toggles panel visibility accordingly.
    private func installFinderActivationWatcher() {
        let wc = NSWorkspace.shared.notificationCenter
        let finderId = "com.apple.finder"

        activationObserver = wc.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil, queue: .main
        ) { [weak self] note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            MainActor.assumeIsolated {
                if app?.bundleIdentifier == finderId {
                    self?.panel?.orderFrontRegardless()
                } else {
                    self?.panel?.orderOut(nil)
                }
            }
        }
        // Don't wait for a notification — sync to the current
        // frontmost app on install so we don't flash the panel
        // incorrectly if we were launched with Finder not in front.
        let frontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        if frontmost != finderId {
            panel?.orderOut(nil)
        }
    }

    private func removeFinderActivationWatcher() {
        if let activationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(activationObserver)
        }
        activationObserver = nil
    }

    func hide() {
        removeFinderActivationWatcher()
        panel?.orderOut(nil)
        panel = nil
    }

    /// Position the panel so it sits to the right of Finder's actual
    /// window frame with a generous gap. Falls back to a fixed
    /// right-edge inset if we can't read Finder's frame.
    private func positionPanel(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let panelW = panel.frame.width
        let panelH = panel.frame.height
        let rightInset: CGFloat = 32
        let gap: CGFloat = 40
        let topInset: CGFloat = 80

        var x = visible.maxX - panelW - rightInset
        if let finderAX = FinderGrid.focusedFinderWindowFrame() {
            // AX and NSWindow use the same x coordinate (left-origin
            // in both cases), so we can pin directly.
            let desired = finderAX.maxX + gap
            if desired + panelW <= visible.maxX - rightInset {
                x = desired
            }
        }
        let y = visible.maxY - panelH - topInset
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    /// Seamless end-of-drill: close the drill's Finder window, drop
    /// the floating panel, activate the tutor app, and fire confetti
    /// from within the tutor window.
    ///
    /// The close-then-delete order matters and is sequenced via
    /// `Task`: we close the drill window, wait long enough for
    /// Finder to actually process the close, delete the tmp folder,
    /// then sweep once more — because when Finder's window was
    /// still open at delete time it auto-navigates up to the parent
    /// `/T/` dir rather than closing, and that sweep catches those.
    func finish(engine: FinderDrillEngine) {
        Task { @MainActor in
            await teardown(engine: engine)
            NSApp.activate(ignoringOtherApps: true)
            Confetti.fireBurst(times: 2, interval: 0.35)
        }
    }

    /// Same teardown as `finish` but without the celebratory hop
    /// back + confetti. Called when the student bypasses a drill
    /// mid-way (e.g. pressing `]` to skip the Finder lesson). The
    /// cleanup still needs to run — leftover Finder windows or
    /// tmp folders are visible mess.
    func abort(engine: FinderDrillEngine) {
        Task { @MainActor in
            await teardown(engine: engine)
        }
    }

    /// Shared close → delete → sweep sequence. The exact timing
    /// matters: when Finder's drill window is still open at the
    /// moment we delete its folder, Finder auto-navigates it up to
    /// the parent `/T/` dir instead of closing. Close first, let
    /// Finder process, delete, sweep the parent.
    private func teardown(engine: FinderDrillEngine) async {
        let folder = engine.folder
        closeDrillFinderWindows(matching: folder)
        hide()
        try? await Task.sleep(for: .milliseconds(250))
        engine.stop()
        try? await Task.sleep(for: .milliseconds(150))
        closeDrillFinderWindows(matching: folder, includeParent: true)
    }

    /// Closes any Finder windows whose displayed folder sits inside
    /// our drill's tmp dir. When `includeParent` is true, also
    /// closes windows showing the immediate parent (e.g. the
    /// per-user `/T/` directory Finder auto-navigates to when its
    /// drill folder is deleted out from under it). AX-only — no
    /// AppleScript — so we don't trip the Automation TCC bucket.
    private func closeDrillFinderWindows(matching folder: URL?,
                                          includeParent: Bool = false) {
        guard let folder,
              let finder = NSRunningApplication.runningApplications(
                withBundleIdentifier: "com.apple.finder"
              ).first else { return }
        let app = AXUIElementCreateApplication(finder.processIdentifier)
        var windows: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            app, kAXWindowsAttribute as CFString, &windows
        ) == .success,
              let list = windows as? [AXUIElement] else { return }

        let folderPath = folder.path
        let folderName = folder.lastPathComponent
        let parentPath = folder.deletingLastPathComponent().path

        for window in list {
            var doc: CFTypeRef?
            AXUIElementCopyAttributeValue(
                window, kAXDocumentAttribute as CFString, &doc
            )
            let docStr = (doc as? String) ?? ""
            let matchesDrill =
                docStr.contains(folderName) || docStr.contains(folderPath)
            let matchesParent = includeParent && docStr.contains(parentPath)
            guard matchesDrill || matchesParent else { continue }

            var closeButton: CFTypeRef?
            if AXUIElementCopyAttributeValue(
                window, kAXCloseButtonAttribute as CFString, &closeButton
            ) == .success, let closeButton {
                AXUIElementPerformAction(
                    closeButton as! AXUIElement,
                    kAXPressAction as CFString
                )
            }
        }
    }
}
