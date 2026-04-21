import AppKit
import SwiftUI

/// Borderless, non-activating NSPanel that floats next to the target
/// app (Notes, Mail) during an external-text drill. Sibling to
/// FinderDrillPanel — same window class, same Space/activation
/// semantics — but hosts the external-text coaching view and keys
/// visibility off the target app's bundle identifier instead of
/// Finder's.
@MainActor
final class ExternalTextDrillPanel {
    static let shared = ExternalTextDrillPanel()

    private var panel: NSPanel?
    private var activationObserver: NSObjectProtocol?
    private var engineRef: ExternalTextDrillEngine?

    func show(engine: ExternalTextDrillEngine, modeMonitor: ModeMonitor) {
        engineRef = engine
        if let panel {
            panel.orderFrontRegardless()
            return
        }

        let view = ExternalTextDrillCoachingView(engine: engine, modeMonitor: modeMonitor)
        let hosting = NSHostingController(rootView: view)
        hosting.view.setFrameSize(NSSize(width: 360, height: 170))
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
        panel.hasShadow = false

        positionPanel(panel, bundleIdentifier: engine.surface.bundleIdentifier)

        panel.orderFrontRegardless()
        self.panel = panel
        installActivationWatcher(targetBundleId: engine.surface.bundleIdentifier)
    }

    func hide() {
        removeActivationWatcher()
        panel?.orderOut(nil)
        panel = nil
        engineRef = nil
    }

    /// End-of-drill finish: tear down the surface via the engine,
    /// drop the panel, hop back to the tutor with confetti.
    func finish(engine: ExternalTextDrillEngine) {
        Task { @MainActor in
            engine.stop()
            hide()
            bringTutorForward()
            Confetti.fireBurst(times: 2, interval: 0.35)
        }
    }

    /// NSApp.activate alone isn't enough to steal focus from Notes —
    /// macOS ignores the request on Sequoia+ unless we have a user-
    /// interaction token. The Finder drill ducked this by closing
    /// Finder's drill window (Finder naturally lost focus). For Notes
    /// we explicitly activate the tutor process and order the main
    /// window front so the completion page is what the student sees.
    private func bringTutorForward() {
        NSRunningApplication.current.activate(options: [.activateAllWindows])
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" })
            ?? NSApp.mainWindow
            ?? NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }

    /// Teardown without the celebratory hop. Called when the student
    /// bypasses the step mid-drill with `]`.
    func abort(engine: ExternalTextDrillEngine) {
        Task { @MainActor in
            engine.stop()
            hide()
        }
    }

    // MARK: - Activation

    /// Keep the panel visible only while the target app is frontmost.
    /// Matches FinderDrillPanel's behavior — the coaching card
    /// shouldn't nag while the student is in Slack or a browser.
    private func installActivationWatcher(targetBundleId: String) {
        let wc = NSWorkspace.shared.notificationCenter
        activationObserver = wc.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil, queue: .main
        ) { [weak self] note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            MainActor.assumeIsolated {
                if app?.bundleIdentifier == targetBundleId {
                    self?.panel?.orderFrontRegardless()
                } else {
                    self?.panel?.orderOut(nil)
                }
            }
        }
        let frontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        if frontmost != targetBundleId { panel?.orderOut(nil) }
    }

    private func removeActivationWatcher() {
        if let activationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(activationObserver)
        }
        activationObserver = nil
    }

    // MARK: - Positioning

    /// Sit to the right of the target app's frontmost window, with a
    /// gap. Falls back to a right-edge anchor if we can't read the
    /// app's frame.
    private func positionPanel(_ panel: NSPanel, bundleIdentifier: String) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let panelW = panel.frame.width
        let panelH = panel.frame.height
        let rightInset: CGFloat = 32
        let gap: CGFloat = 40
        let topInset: CGFloat = 80

        var x = visible.maxX - panelW - rightInset
        if let appFrame = frontWindowFrame(bundleIdentifier: bundleIdentifier) {
            let desired = appFrame.maxX + gap
            if desired + panelW <= visible.maxX - rightInset {
                x = desired
            }
        }
        let y = visible.maxY - panelH - topInset
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func frontWindowFrame(bundleIdentifier: String) -> CGRect? {
        guard let app = NSRunningApplication.runningApplications(
            withBundleIdentifier: bundleIdentifier
        ).first else { return nil }
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var windows: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            axApp, kAXWindowsAttribute as CFString, &windows
        ) == .success,
              let list = windows as? [AXUIElement],
              let first = list.first else { return nil }
        var posValue: CFTypeRef?
        var sizeValue: CFTypeRef?
        AXUIElementCopyAttributeValue(first, kAXPositionAttribute as CFString, &posValue)
        AXUIElementCopyAttributeValue(first, kAXSizeAttribute as CFString, &sizeValue)
        var pos = CGPoint.zero
        var size = CGSize.zero
        if let posValue {
            AXValueGetValue(posValue as! AXValue, .cgPoint, &pos)
        }
        if let sizeValue {
            AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        }
        // AX uses top-left origin in screen coords; NSWindow expects
        // bottom-left. Convert.
        guard let screen = NSScreen.screens.first else { return nil }
        let flippedY = screen.frame.maxY - pos.y - size.height
        return CGRect(x: pos.x, y: flippedY, width: size.width, height: size.height)
    }
}
