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
    private let titlePrefix = "kV Drill –"

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
        return PreparedSurface(
            bundleIdentifier: bundleIdentifier,
            documentIdentifier: noteId
        )
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
    func sweepOrphans() async {
        let escapedFolder = escape(folderName)
        let escapedPrefix = escape(titlePrefix)
        let script = """
        tell application "Notes"
            try
                set targetFolder to folder "\(escapedFolder)"
                repeat with n in (notes of targetFolder)
                    if name of n starts with "\(escapedPrefix)" then
                        delete n
                    end if
                end repeat
            end try
        end tell
        """
        _ = try? await OSAScriptRunner.runWithRetry(script, timeout: 6)
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
