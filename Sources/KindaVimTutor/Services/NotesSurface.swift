import AppKit
import Foundation

/// Adapter for running a text-editing drill in Apple Notes.
///
/// Notes doesn't expose a first-class "scratch" concept, so each
/// drill creates a fresh note inside a dedicated folder
/// ("kindaVim Tutor") in whatever the student's default account is.
/// Cleanup deletes the note when the drill ends. Orphaned notes
/// from a crashed drill are swept on app launch.
///
/// All Notes interaction happens via `osascript` in a child
/// process with a hard timeout — never synchronously on the main
/// thread. See `OSAScriptRunner` for the rationale.
struct NotesSurface: ExternalTextSurface {
    let displayName = "Notes"
    let bundleIdentifier = "com.apple.Notes"

    /// Folder we always drop drill notes into. Created on first use.
    private let folderName = "kindaVim Tutor"
    /// Every drill note starts with this marker line — makes orphan
    /// sweeping cheap (search by title prefix).
    private let titlePrefix = "KindaVim Drill –"

    // MARK: - Usability

    func isUsable() async -> UsabilityStatus {
        // Notes app is a system app — we don't check bundle presence.
        // The most common real-world failure is "no notes account
        // enabled" (e.g. user signed out of iCloud and never turned
        // on On My Mac). AppleScript's `default account` returns the
        // name, or throws if none exists.
        let script = """
        tell application "Notes"
            try
                set n to name of default account
                return n
            on error
                return ""
            end try
        end tell
        """
        do {
            _ = try? await warmup()
            let result = try await OSAScriptRunner.runWithRetry(script, timeout: 4)
            if result.isEmpty {
                return .needsSetup(reason: "No Notes account is enabled.")
            }
            return .ready
        } catch {
            return .needsSetup(reason: "Notes isn't responding.")
        }
    }

    // MARK: - Prepare

    func prepare(body: String) async throws -> PreparedSurface {
        _ = try? await warmup()

        let title = "\(titlePrefix) \(UUID().uuidString.prefix(6))"
        let escapedTitle = escape(title)
        let escapedFolder = escape(folderName)
        // Notes stores bodies as HTML. Wrap plain text in <pre> so
        // spaces, newlines, and punctuation survive without being
        // collapsed by the renderer. Escape HTML metacharacters
        // first so the input can't inject tags.
        let htmlBody = "<pre>\(htmlEscape(body))</pre>"
        let escapedBody = escape(htmlBody)

        // Create the dedicated folder if it doesn't exist, then
        // create the note in it. Return the note's id so cleanup
        // can reference it precisely. Wrapped in try/-609 since
        // first-run after a permission grant sometimes fails once
        // even after the warmup.
        let script = """
        tell application "Notes"
            activate
            set targetFolder to missing value
            repeat with f in folders
                if name of f is "\(escapedFolder)" then
                    set targetFolder to f
                    exit repeat
                end if
            end repeat
            if targetFolder is missing value then
                set targetFolder to make new folder with properties {name:"\(escapedFolder)"}
            end if
            set newNote to make new note at targetFolder with properties ¬
                {name:"\(escapedTitle)", body:"\(escapedBody)"}
            show newNote
            return id of newNote
        end tell
        """

        let noteId = try await OSAScriptRunner.runWithRetry(script, timeout: 8)
        guard !noteId.isEmpty else {
            throw ExternalTextSurfaceError.surfaceNotResolved
        }
        // `show newNote` routes Notes to the right note but leaves
        // keyboard focus parked on the sidebar / toolbar — AppleScript
        // has no way to focus the body. Walk Notes' AX tree for the
        // AXTextArea and mark it focused so the student can type /
        // use kindaVim immediately without having to click in.
        try? await Task.sleep(for: .milliseconds(350))
        focusBodyTextArea(expectedBody: body)
        return PreparedSurface(
            bundleIdentifier: bundleIdentifier,
            documentIdentifier: noteId
        )
    }

    /// Find the frontmost Notes window's body text area and focus it.
    ///
    /// Notes exposes *both* the title and the body as AXTextArea —
    /// depth-first "first text area" picks the title. We disambiguate
    /// by value: the body area's AXValue contains the seed text we
    /// just wrote; the title is short and different. Largest value
    /// length wins as a fallback.
    private func focusBodyTextArea(expectedBody: String) {
        guard let notes = NSRunningApplication.runningApplications(
            withBundleIdentifier: bundleIdentifier
        ).first else { return }
        let app = AXUIElementCreateApplication(notes.processIdentifier)
        var focusedWindow: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            app, kAXFocusedWindowAttribute as CFString, &focusedWindow
        ) == .success, let win = focusedWindow else {
            AppLogger.shared.info("extDrill", "focusBodyNoWindow", fields: [:])
            return
        }
        let window = win as! AXUIElement
        var areas: [(element: AXUIElement, value: String)] = []
        collectTextAreas(in: window, into: &areas)
        AppLogger.shared.info("extDrill", "focusBodyAreas",
                              fields: ["count": "\(areas.count)"])
        guard !areas.isEmpty else {
            sendReturnKeystroke()
            return
        }
        // Prefer the area whose value contains a unique chunk of the
        // seed body. HTML wrapping + quirks mean exact match is
        // unreliable, so match on a distinctive substring.
        let marker = expectedBody
            .split(separator: "\n")
            .first
            .map(String.init) ?? expectedBody
        let target = areas.first { $0.value.contains(marker) }
            ?? areas.max { $0.value.count < $1.value.count }
        guard let target else { return }
        AppLogger.shared.info("extDrill", "focusBodyPicked",
                              fields: ["len": "\(target.value.count)"])
        AXUIElementSetAttributeValue(
            target.element, kAXFocusedAttribute as CFString, kCFBooleanTrue
        )
        // Notes rebounds focus back to the title on fresh notes even
        // after we set AXFocused on the body. Synthesise a click in
        // the middle of the body's frame — that puts a caret in the
        // note body the way the user's click would, and Notes doesn't
        // override it.
        if let center = frameCenter(of: target.element) {
            synthesiseClick(at: center)
        }
    }

    /// Read the AX position + size of an element and return a point
    /// near the top-left of its frame — where the first line of body
    /// text lives. Clicking center-of-frame lands the caret at the
    /// end of the seed (below the last line), which is the wrong
    /// starting position for most drills. Top-anchored caret means
    /// students start from where the seed begins.
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
        // Notes exposes the title + body as a single AXTextArea
        // region, so clicking near the top lands in the title. The
        // center reliably lands in the body. Students can `gg` / `k`
        // to reach line 1 — better than fighting the title.
        return CGPoint(x: pos.x + size.width / 2,
                       y: pos.y + size.height / 2)
    }

    /// Post a single left-click at the given screen point via
    /// CGEvent. Used to plant a caret inside the note body — AX
    /// focus alone isn't enough because Notes re-focuses the title
    /// on fresh notes.
    private func synthesiseClick(at point: CGPoint) {
        let src = CGEventSource(stateID: .hidSystemState)
        let down = CGEvent(mouseEventSource: src, mouseType: .leftMouseDown,
                           mouseCursorPosition: point, mouseButton: .left)
        let up = CGEvent(mouseEventSource: src, mouseType: .leftMouseUp,
                         mouseCursorPosition: point, mouseButton: .left)
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }

    /// Depth-first collect every AXTextArea in the subtree, with its
    /// current string value (empty string if AX didn't return one).
    private func collectTextAreas(in element: AXUIElement,
                                  into out: inout [(element: AXUIElement, value: String)]) {
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

    /// Synthesize a Return keystroke so Notes' native "commit title,
    /// focus body" keyboard binding fires. Last-ditch fallback when
    /// the AX focus call didn't land on the body.
    private func sendReturnKeystroke() {
        let src = CGEventSource(stateID: .hidSystemState)
        let down = CGEvent(keyboardEventSource: src, virtualKey: 0x24, keyDown: true)
        let up = CGEvent(keyboardEventSource: src, virtualKey: 0x24, keyDown: false)
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }

    // MARK: - Cleanup

    func cleanup(_ prepared: PreparedSurface) async {
        let escapedId = escape(prepared.documentIdentifier)
        let script = """
        tell application "Notes"
            try
                set n to note id "\(escapedId)"
                delete n
            end try
        end tell
        """
        _ = try? await OSAScriptRunner.runWithRetry(script, timeout: 4)
    }

    /// Scan for any leftover `kV Drill –` notes in our folder and
    /// delete them. Call at app launch.
    ///
    /// Two-pass: collect matching note ids first, then delete by id.
    /// Deleting while iterating `notes of folder` invalidates the
    /// iterator and throws -1728 (`Can't get item 1 of every note`),
    /// which our outer `try` swallowed silently — orphans accumulated
    /// even though the sweep appeared to run.
    func sweepOrphans() async {
        let escapedFolder = escape(folderName)
        let escapedPrefix = escape(titlePrefix)
        let script = """
        tell application "Notes"
            try
                set ids to {}
                repeat with n in (notes of folder "\(escapedFolder)")
                    if name of n starts with "\(escapedPrefix)" then
                        set end of ids to id of n
                    end if
                end repeat
                repeat with theId in ids
                    try
                        delete note id theId
                    end try
                end repeat
                return "deleted " & (count of ids)
            end try
        end tell
        """
        do {
            let result = try await OSAScriptRunner.runWithRetry(script, timeout: 8)
            AppLogger.shared.info("extDrill", "sweepComplete",
                                  fields: ["result": result])
        } catch {
            AppLogger.shared.info("extDrill", "sweepFailed",
                                  fields: ["error": "\(error)"])
        }
    }

    // MARK: - Warmup

    /// A cheap query against Notes to establish the AE connection
    /// before we do real work. `version` is the one scripting
    /// property that's documented to return immediately — heavier
    /// queries (folders, accounts) can hang if Notes is mid-sync.
    /// Called before every substantive operation; cheap enough to
    /// run repeatedly.
    private func warmup() async throws {
        let script = """
        tell application "Notes" to return version
        """
        _ = try await OSAScriptRunner.runWithRetry(script, timeout: 4, retries: 2)
    }

    // MARK: - AppleScript string escaping

    /// AppleScript string literals use backslash escapes for `"`
    /// and `\`. Newlines are preserved literally in a `"..."`
    /// literal but it's safer to convert to `\n` for multi-line
    /// bodies.
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

    /// Escape HTML metacharacters so the student-visible body can't
    /// inject tags into Notes' rendered view.
    private func htmlEscape(_ string: String) -> String {
        var result = ""
        for ch in string {
            switch ch {
            case "&": result.append("&amp;")
            case "<": result.append("&lt;")
            case ">": result.append("&gt;")
            case "\"": result.append("&quot;")
            default: result.append(ch)
            }
        }
        return result
    }
}
