import AppKit
import ApplicationServices
import Foundation

/// Adapter for running a text-editing drill in Apple Mail.
///
/// Each drill creates a fresh outgoing message (compose window) with
/// the seed body pre-populated and a distinctive subject so orphan
/// cleanup can find leftover drills from a crashed session.
///
/// The compose window is never saved or sent — cleanup closes it
/// silently. If the student saves manually, the draft lands in the
/// Drafts mailbox where the orphan sweep will catch it on launch.
///
/// Like NotesSurface, all AppleScript runs in an out-of-process
/// osascript child with a hard timeout. Never on the main thread.
struct MailSurface: ExternalTextSurface {
    let displayName = "Mail"
    let bundleIdentifier = "com.apple.mail"

    /// Subject prefix on every drill draft — makes sweeping cheap
    /// and unambiguous. Includes the human-facing product name so
    /// a student who spots the draft in their outbox knows it's us.
    private let subjectPrefix = "KindaVim Drill –"

    // MARK: - Usability

    func isUsable() async -> UsabilityStatus {
        // Mail with no configured accounts can still run compose
        // windows (you just can't send), but many students will find
        // it confusing. Surface a helpful error when there are no
        // accounts at all.
        let script = """
        tell application "Mail"
            try
                return (count of accounts) as string
            on error
                return "0"
            end try
        end tell
        """
        do {
            _ = try? await warmup()
            let result = try await OSAScriptRunner.runWithRetry(script, timeout: 4)
            let count = Int(result.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            if count == 0 {
                return .needsSetup(reason: "Mail has no configured accounts.")
            }
            return .ready
        } catch {
            return .needsSetup(reason: "Mail isn't responding.")
        }
    }

    // MARK: - Prepare

    func prepare(body: String) async throws -> PreparedSurface {
        _ = try? await warmup()

        let shortId = String(UUID().uuidString.prefix(6))
        let subject = "\(subjectPrefix) \(shortId)"
        let escapedSubject = escape(subject)
        let escapedBody = escape(body)

        // Create the outgoing message, make its compose window
        // visible, and activate Mail so the student can start
        // editing. Returning the subject (not an AppleScript id)
        // keeps the handle unique enough for later cleanup and
        // dodges AppleScript's fragile reference ids.
        let script = """
        tell application "Mail"
            activate
            set newMsg to make new outgoing message with properties ¬
                {subject:"\(escapedSubject)", content:"\(escapedBody)", visible:true}
            return "\(escapedSubject)"
        end tell
        """
        let identifier = try await OSAScriptRunner.runWithRetry(script, timeout: 8)
        guard !identifier.isEmpty else {
            throw ExternalTextSurfaceError.surfaceNotResolved
        }
        // Mail's compose window opens with focus on the To: field.
        // Tab into the body so the student can start typing / using
        // kindaVim immediately.
        try? await Task.sleep(for: .milliseconds(400))
        focusBody()
        return PreparedSurface(
            bundleIdentifier: bundleIdentifier,
            documentIdentifier: subject
        )
    }

    // MARK: - Cleanup

    func cleanup(_ prepared: PreparedSurface) async {
        let escapedSubject = escape(prepared.documentIdentifier)
        // Close the compose window without saving. Mail's AppleScript
        // supports `close outgoing message saving no`, which bypasses
        // the "save this draft?" prompt. If the student already sent
        // it (unusual for a drill), there's nothing to close — the
        // `try` block swallows it silently.
        let script = """
        tell application "Mail"
            try
                repeat with m in outgoing messages
                    if subject of m is "\(escapedSubject)" then
                        close m saving no
                    end if
                end repeat
            end try
        end tell
        """
        _ = try? await OSAScriptRunner.runWithRetry(script, timeout: 4)
    }

    /// Close any stale drill compose windows or saved drafts whose
    /// subject starts with our prefix. Called at app launch.
    func sweepOrphans() async {
        let escapedPrefix = escape(subjectPrefix)
        // Two passes: close live compose windows first, then delete
        // any drafts the student saved into a mailbox. Mail's
        // message collection in mailboxes doesn't support filtering
        // by subject with a `starts with` comparator in AppleScript
        // reliably, so collect ids first and delete in a second
        // loop (same pattern that bit us in NotesSurface).
        let script = """
        tell application "Mail"
            try
                repeat with m in outgoing messages
                    if subject of m starts with "\(escapedPrefix)" then
                        close m saving no
                    end if
                end repeat
            end try
            try
                set draftMailboxes to {}
                repeat with a in accounts
                    try
                        set end of draftMailboxes to drafts mailbox of a
                    end try
                end try
                set ids to {}
                repeat with mb in draftMailboxes
                    repeat with msg in (messages of mb)
                        if subject of msg starts with "\(escapedPrefix)" then
                            set end of ids to id of msg
                        end if
                    end repeat
                end repeat
                repeat with theId in ids
                    try
                        set msg to first message of drafts mailbox whose id is theId
                        delete msg
                    end try
                end repeat
                return "outgoing+drafts cleaned"
            end try
        end tell
        """
        do {
            let result = try await OSAScriptRunner.runWithRetry(script, timeout: 10)
            AppLogger.shared.info("extDrill", "mailSweepComplete",
                                  fields: ["result": result])
        } catch {
            AppLogger.shared.info("extDrill", "mailSweepFailed",
                                  fields: ["error": "\(error)"])
        }
    }

    // MARK: - Focus body

    /// Mail compose windows open with focus on the To: header field.
    /// Walk the frontmost compose window, find the body AXTextArea
    /// (inside an AXScrollArea → AXWebArea), and click its center
    /// to plant a caret. Same shape as NotesSurface.focusBodyTextArea.
    private func focusBody() {
        guard let mail = NSRunningApplication.runningApplications(
            withBundleIdentifier: bundleIdentifier
        ).first else { return }
        let app = AXUIElementCreateApplication(mail.processIdentifier)
        var focusedWindow: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            app, kAXFocusedWindowAttribute as CFString, &focusedWindow
        ) == .success, let win = focusedWindow else {
            AppLogger.shared.info("extDrill", "mailFocusNoWindow", fields: [:])
            return
        }
        var areas: [(element: AXUIElement, value: String, area: CGFloat)] = []
        collectTextAreas(in: win as! AXUIElement, into: &areas)
        AppLogger.shared.info("extDrill", "mailFocusAreas",
                              fields: ["count": "\(areas.count)"])
        // Compose body is the largest text area by frame — the
        // header fields (To, Cc, Subject) are all small AXTextFields
        // and shouldn't show up here, but if any text area is tiny
        // it's probably not the body.
        let target = areas.max { $0.area < $1.area }
        guard let target else { return }
        AXUIElementSetAttributeValue(
            target.element, kAXFocusedAttribute as CFString, kCFBooleanTrue
        )
        if let center = frameCenter(of: target.element) {
            synthesiseClick(at: center)
        }
    }

    private func collectTextAreas(
        in element: AXUIElement,
        into out: inout [(element: AXUIElement, value: String, area: CGFloat)]
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
            var sizeValue: CFTypeRef?
            AXUIElementCopyAttributeValue(
                element, kAXSizeAttribute as CFString, &sizeValue
            )
            var size = CGSize.zero
            if let sizeValue {
                AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
            }
            out.append((element, (value as? String) ?? "",
                        size.width * size.height))
        }
        var children: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element, kAXChildrenAttribute as CFString, &children
        ) == .success, let list = children as? [AXUIElement] else { return }
        for child in list {
            collectTextAreas(in: child, into: &out)
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

    // MARK: - Warmup

    private func warmup() async throws {
        let script = """
        tell application "Mail" to return version
        """
        _ = try await OSAScriptRunner.runWithRetry(script, timeout: 4, retries: 2)
    }

    // MARK: - Escaping

    private func escape(_ string: String) -> String {
        var result = ""
        for ch in string {
            switch ch {
            case "\\":  result.append("\\\\")
            case "\"":  result.append("\\\"")
            case "\n":  result.append("\\n")
            case "\r":  result.append("\\r")
            default:    result.append(ch)
            }
        }
        return result
    }
}
