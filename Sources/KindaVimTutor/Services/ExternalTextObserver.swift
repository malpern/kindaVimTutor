import AppKit
import ApplicationServices
import Foundation

/// AX observer for the currently-focused text element of a target
/// application (Notes, Mail, …). Sibling to FinderSelectionObserver
/// but specialised for text surfaces: we want to know when the
/// *text value* changes so the drill engine can re-evaluate its
/// completion predicate.
///
/// Notifications we register for, on the app's AXUIElement:
///   - `AXValueChanged` — body text edits
///   - `AXSelectedTextChanged` — cursor / selection movement
///   - `AXFocusedUIElementChanged` — student clicked into a
///     different field (subject vs body, etc.); we re-read on
///     focus changes so we don't miss edits against a moved
///     target.
@MainActor
final class ExternalTextObserver {
    private var observer: AXObserver?
    private var appElement: AXUIElement?
    private var onChange: ((String) -> Void)?

    @discardableResult
    func start(
        bundleIdentifier: String,
        onChange: @escaping (String) -> Void
    ) -> Bool {
        stop()
        self.onChange = onChange

        guard let app = NSRunningApplication.runningApplications(
            withBundleIdentifier: bundleIdentifier
        ).first else { return false }
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        self.appElement = appElement

        var rawObserver: AXObserver?
        let createErr = AXObserverCreate(app.processIdentifier,
                                          Self.callback,
                                          &rawObserver)
        guard createErr == .success, let obs = rawObserver else {
            AppLogger.shared.info("extDrill", "observerCreateFailed",
                                  fields: ["err": "\(createErr)"])
            return false
        }
        self.observer = obs

        let refcon = Unmanaged.passUnretained(self).toOpaque()
        let notes = [
            kAXValueChangedNotification as String,
            kAXSelectedTextChangedNotification as String,
            kAXFocusedUIElementChangedNotification as String,
            kAXFocusedWindowChangedNotification as String,
        ]
        for note in notes {
            _ = AXObserverAddNotification(obs, appElement, note as CFString, refcon)
        }

        CFRunLoopAddSource(
            CFRunLoopGetMain(),
            AXObserverGetRunLoopSource(obs),
            .defaultMode
        )

        // Seed with the current text so the engine has state to
        // compare against on the first notification.
        onChange(readFocusedText() ?? "")
        return true
    }

    func stop() {
        if let obs = observer {
            CFRunLoopRemoveSource(
                CFRunLoopGetMain(),
                AXObserverGetRunLoopSource(obs),
                .defaultMode
            )
        }
        observer = nil
        appElement = nil
        onChange = nil
    }

    deinit {
        // Follows the same invariant as FinderSelectionObserver —
        // callers must call stop() before releasing. CF teardown
        // handles the residue if they don't, but we don't try to
        // do any MainActor work here.
    }

    // MARK: - Read current text

    /// Walks the focused element + its siblings looking for a text
    /// area or text field and returns its AXValue as a string.
    /// Falls back to the focused UI element itself.
    private func readFocusedText() -> String? {
        guard let appElement else { return nil }
        var focused: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(
            appElement, kAXFocusedUIElementAttribute as CFString, &focused
        )
        guard err == .success, let focused else { return nil }
        return extractValue(from: focused as! AXUIElement)
    }

    /// Recursively searches `element`'s ancestry up to a text-like
    /// role and returns its AXValue. Walks upward because when the
    /// student is editing inside a rich-text area, the focused
    /// element is often a run or line, not the container that
    /// exposes the full body.
    private func extractValue(from element: AXUIElement) -> String? {
        if let text = readValue(of: element) { return text }
        var parent: CFTypeRef?
        if AXUIElementCopyAttributeValue(
            element, kAXParentAttribute as CFString, &parent
        ) == .success, let parent {
            return extractValue(from: parent as! AXUIElement)
        }
        return nil
    }

    private func readValue(of element: AXUIElement) -> String? {
        var role: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role)
        let roleStr = role as? String ?? ""
        // Only return values from editable text containers, not
        // arbitrary elements that happen to expose AXValue (like
        // buttons or rows).
        let textRoles: Set<String> = [
            "AXTextArea", "AXTextField", "AXWebArea"
        ]
        guard textRoles.contains(roleStr) else { return nil }
        var value: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value)
        return value as? String
    }

    // MARK: - C callback bridge

    private static let callback: AXObserverCallback = { _, _, _, refcon in
        guard let refcon else { return }
        let observer = Unmanaged<ExternalTextObserver>
            .fromOpaque(refcon).takeUnretainedValue()
        // AX run-loop is main; we installed on main run loop.
        MainActor.assumeIsolated {
            observer.handleNotification()
        }
    }

    private func handleNotification() {
        let text = readFocusedText() ?? ""
        onChange?(text)
    }
}
