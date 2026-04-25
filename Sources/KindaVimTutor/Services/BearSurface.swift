import AppKit
import Foundation

/// Adapter for running a text-editing drill inside Bear
/// (net.shinyfrog.bear). Bear exposes a rich `x-callback-url` API
/// and is a native AppKit app, so kindaVim's AX observation just
/// works — but Bear has almost no AppleScript surface, so every
/// mutation goes through URLs.
///
/// Flow:
///  - `prepare(body:)` registers a callback token, fires
///    `bear://x-callback-url/create?…&x-success=kindavim-tutor://<token>`,
///    and awaits the `identifier` returned on the callback.
///  - `cleanup(_:)` fires `bear://x-callback-url/trash?id=…&token=…`
///    using the per-user Bear API token from Keychain. Silent no-op
///    when no token is configured — the orphan sweep catches those.
///  - `sweepOrphans()` walks pending titles via `/search` and trashes
///    them with the API token, best-effort.
///
/// The Bear API token is only required for trash (cleanup). Without
/// it, drills still work — they just leave notes behind that the
/// student can delete manually.
struct BearSurface: ExternalTextSurface {
    let displayName = "Bear"
    let bundleIdentifier = "net.shinyfrog.bear"

    /// Every drill note's title starts with this marker so orphan
    /// cleanup can find them by search. Keep it distinctive enough
    /// that the student's real notes are never confused for drills.
    static let titlePrefix = "KindaVim Drill –"

    /// How long to wait for Bear to fire our `x-success` callback.
    /// Bear normally replies within a second; give headroom for
    /// cold starts / first-permission prompts.
    private let createTimeout: Duration = .seconds(8)

    // MARK: - Usability

    func isUsable() async -> UsabilityStatus {
        // Bear is a third-party app — check bundle presence before
        // attempting anything. (Notes/Mail skip this because they're
        // system apps that always exist.)
        if NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: bundleIdentifier
        ) == nil {
            return .missing
        }
        return .ready
    }

    // MARK: - Prepare

    func prepare(body: String) async throws -> PreparedSurface {
        let token = "bear-" + UUID().uuidString.prefix(8).lowercased()
        let title = "\(Self.titlePrefix) \(UUID().uuidString.prefix(6))"

        // Register the awaiter BEFORE opening the URL so there's no
        // race between Bear's very-fast callback and our awaiter
        // registration.
        let callbackTask = Task { @MainActor in
            await URLCallbackHub.shared.await_(token: token)
        }

        guard let createURL = bearCreateURL(
            title: title, body: body, callbackToken: token
        ) else {
            throw ExternalTextSurfaceError.surfaceNotResolved
        }
        await MainActor.run { _ = NSWorkspace.shared.open(createURL) }

        // Schedule a watchdog that cancels the awaiter if Bear
        // never fires x-success. Done as a detached Task whose
        // sleep is *cancellable* — when the callback fires first
        // we cancel the watchdog and the sleep wakes immediately,
        // so prepare() returns without blocking on the full
        // timeout the way withTaskGroup did.
        let watchdog = Task {
            try? await Task.sleep(for: createTimeout)
            if !Task.isCancelled {
                await MainActor.run { URLCallbackHub.shared.cancel(token: token) }
            }
        }
        let payload = await callbackTask.value
        watchdog.cancel()

        guard let identifier = payload["identifier"], !identifier.isEmpty else {
            throw ExternalTextSurfaceError.scriptingTimedOut
        }
        AppLogger.shared.info("extDrill", "bearCreated", fields: [
            "id": String(identifier.prefix(8)),
            "title": title,
        ])

        // Bear delivers x-success by *opening* our kindavim-tutor://
        // URL, which activates the tutor app and yanks focus away
        // from Bear. Re-activate Bear before the student starts
        // typing so kindaVim's keystrokes land in the right window.
        await MainActor.run {
            if let bear = NSRunningApplication.runningApplications(
                withBundleIdentifier: bundleIdentifier
            ).first {
                bear.activate(options: [])
            }
        }

        // After Bear is back in front, walk its AX tree and mark
        // the body text area focused so the student can type (and
        // kindaVim can intercept keystrokes) without having to
        // click into the body first.
        try? await Task.sleep(for: .milliseconds(400))
        focusBodyTextArea(expectedBody: body)
        return PreparedSurface(
            bundleIdentifier: bundleIdentifier,
            documentIdentifier: identifier
        )
    }

    // MARK: - Focus helpers

    /// Walk Bear's AX hierarchy, pick the text area that contains
    /// our seed body, and mark it focused. On failure, click in the
    /// middle of the widest text area as a fallback — AXFocused
    /// alone sometimes doesn't take on Bear.
    private func focusBodyTextArea(expectedBody: String) {
        guard let bear = NSRunningApplication.runningApplications(
            withBundleIdentifier: bundleIdentifier
        ).first else { return }
        let app = AXUIElementCreateApplication(bear.processIdentifier)
        var focusedWindow: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            app, kAXFocusedWindowAttribute as CFString, &focusedWindow
        ) == .success, let win = focusedWindow else {
            AppLogger.shared.info("extDrill", "bearFocusNoWindow", fields: [:])
            return
        }
        let window = win as! AXUIElement
        var areas: [(element: AXUIElement, value: String)] = []
        collectTextAreas(in: window, into: &areas)
        guard !areas.isEmpty else {
            AppLogger.shared.info("extDrill", "bearFocusNoTextAreas",
                                  fields: [:])
            return
        }
        let marker = expectedBody
            .split(separator: "\n")
            .first
            .map(String.init) ?? expectedBody
        let target = areas.first { $0.value.contains(marker) }
            ?? areas.max { $0.value.count < $1.value.count }
        guard let target else { return }
        AXUIElementSetAttributeValue(
            target.element, kAXFocusedAttribute as CFString, kCFBooleanTrue
        )
        if let center = frameCenter(of: target.element) {
            synthesiseClick(at: center)
        }
    }

    private func frameCenter(of element: AXUIElement) -> CGPoint? {
        var posValue: CFTypeRef?
        var sizeValue: CFTypeRef?
        AXUIElementCopyAttributeValue(
            element, kAXPositionAttribute as CFString, &posValue
        )
        AXUIElementCopyAttributeValue(
            element, kAXSizeAttribute as CFString, &sizeValue
        )
        guard let posValue, let sizeValue else { return nil }
        var pos = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(posValue as! AXValue, .cgPoint, &pos)
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        guard size.width > 0, size.height > 0 else { return nil }
        return CGPoint(x: pos.x + size.width / 2,
                       y: pos.y + size.height / 2)
    }

    private func synthesiseClick(at point: CGPoint) {
        let src = CGEventSource(stateID: .hidSystemState)
        let down = CGEvent(mouseEventSource: src, mouseType: .leftMouseDown,
                           mouseCursorPosition: point, mouseButton: .left)
        let up = CGEvent(mouseEventSource: src, mouseType: .leftMouseUp,
                         mouseCursorPosition: point, mouseButton: .left)
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }

    private func collectTextAreas(
        in element: AXUIElement,
        into out: inout [(element: AXUIElement, value: String)]
    ) {
        var role: CFTypeRef?
        AXUIElementCopyAttributeValue(
            element, kAXRoleAttribute as CFString, &role
        )
        if (role as? String) == "AXTextArea" {
            var value: CFTypeRef?
            AXUIElementCopyAttributeValue(
                element, kAXValueAttribute as CFString, &value
            )
            out.append((element, (value as? String) ?? ""))
        }
        var children: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element, kAXChildrenAttribute as CFString, &children
        ) == .success, let list = children as? [AXUIElement] else { return }
        for child in list {
            collectTextAreas(in: child, into: &out)
        }
    }

    // MARK: - Cleanup

    func cleanup(_ prepared: PreparedSurface) async {
        guard let apiToken = KeychainStore.get(.bearAPIToken),
              !apiToken.isEmpty
        else {
            AppLogger.shared.info("extDrill", "bearCleanupSkipped",
                                  fields: ["reason": "noToken"])
            return
        }
        guard let idURL = bearTrashURL(id: prepared.documentIdentifier,
                                       apiToken: apiToken) else {
            return
        }
        AppLogger.shared.info("extDrill", "bearCleanupById", fields: [
            "id": String(prepared.documentIdentifier.prefix(8)),
        ])
        await MainActor.run { _ = NSWorkspace.shared.open(idURL) }
    }

    /// Bear's `/trash?search=` pops the search UI instead of
    /// silently trashing matched notes (and ignores
    /// `show_window=no`), so we can't run an orphan sweep at app
    /// launch without yanking Bear forward unexpectedly. Leave this
    /// as a deliberate no-op — per-drill id-based cleanup is the
    /// real path; orphans from past crashes need manual deletion in
    /// Bear's Trash sidebar.
    func sweepOrphans() async {
        AppLogger.shared.info("extDrill", "bearSweepSkipped",
                              fields: ["reason": "searchPopsUI"])
    }

    // MARK: - URL construction

    /// Build `bear://x-callback-url/create` with title, text, and
    /// an x-success callback that returns through `URLCallbackHub`.
    /// Returns nil only on catastrophic encoding failure.
    private func bearCreateURL(
        title: String, body: String, callbackToken: String
    ) -> URL? {
        var components = URLComponents()
        components.scheme = "bear"
        components.host = "x-callback-url"
        components.path = "/create"

        let successURL = "kindavim-tutor://\(callbackToken)"
        components.queryItems = [
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "text", value: body),
            URLQueryItem(name: "open_note", value: "yes"),
            URLQueryItem(name: "show_window", value: "yes"),
            URLQueryItem(name: "new_window", value: "no"),
            URLQueryItem(name: "float", value: "no"),
            URLQueryItem(name: "edit", value: "yes"),
            URLQueryItem(name: "x-success", value: successURL),
        ]
        return components.url
    }

    private func bearTrashURL(id: String, apiToken: String) -> URL? {
        var components = URLComponents()
        components.scheme = "bear"
        components.host = "x-callback-url"
        components.path = "/trash"
        components.queryItems = [
            URLQueryItem(name: "id", value: id),
            URLQueryItem(name: "token", value: apiToken),
            URLQueryItem(name: "show_window", value: "no"),
        ]
        return components.url
    }

}
