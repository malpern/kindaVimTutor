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

    /// Final results surfaced after the drill completes and the panel
    /// has been dismissed — so the tutor window can show a summary.
    private(set) var lastRunSummary: Summary?

    struct Summary {
        let reps: Int
        let moves: Int
        let time: TimeInterval
    }

    func show(engine: FinderDrillEngine, modeMonitor: ModeMonitor) {
        if let panel {
            panel.orderFrontRegardless()
            return
        }

        let view = FinderDrillCoachingView(engine: engine, modeMonitor: modeMonitor)
        let hosting = NSHostingController(rootView: view)
        hosting.view.setFrameSize(NSSize(width: 360, height: 170))

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 170),
            styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
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
        panel.hasShadow = true

        // Top-right of the main screen, inset from the corner.
        if let screen = NSScreen.main {
            let frame = panel.frame
            let x = screen.visibleFrame.maxX - frame.width - 24
            let y = screen.visibleFrame.maxY - frame.height - 24
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.orderFrontRegardless()
        self.panel = panel
    }

    func hide() {
        panel?.orderOut(nil)
        panel = nil
    }

    /// Seamless end-of-drill: close the drill's Finder window, drop
    /// the floating panel, activate the tutor app, and fire confetti
    /// from within the tutor window. Records a summary for any caller
    /// that wants to show it later.
    func finish(engine: FinderDrillEngine) {
        lastRunSummary = Summary(
            reps: engine.results.count,
            moves: engine.totalMoves,
            time: engine.totalTime
        )
        closeDrillFinderWindows(folder: engine.folder)
        hide()
        // stop() deletes the tmp folder and tears down the observer;
        // call after the Finder window close so the folder path is
        // still resolvable above.
        engine.stop()
        NSApp.activate(ignoringOtherApps: true)
        Confetti.fireBurst(times: 2, interval: 0.35)
    }

    /// Closes any Finder windows whose displayed folder sits inside
    /// our tmp dir. AX-only — no AppleScript — so we don't trip the
    /// Automation TCC bucket or risk another hang.
    private func closeDrillFinderWindows(folder: URL?) {
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
        for window in list {
            var doc: CFTypeRef?
            AXUIElementCopyAttributeValue(
                window, kAXDocumentAttribute as CFString, &doc
            )
            // `AXDocument` returns a file URL string for Finder windows.
            let docStr = (doc as? String) ?? ""
            if docStr.contains(folder.lastPathComponent) ||
               docStr.contains(folderPath) {
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
}
