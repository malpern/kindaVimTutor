import AppKit
import Foundation

/// An app-specific adapter for opening, populating, observing, and
/// tearing down a text-editing surface in a real macOS app. Every
/// "in the wild" drill interacts with the system app only via
/// this protocol so the engine above can stay app-agnostic.
protocol ExternalTextSurface: Sendable {
    /// Shown in the coaching panel header ("Notes", "Mail", …).
    var displayName: String { get }

    /// Bundle identifier of the app we'll be activating + reading
    /// AX from ("com.apple.Notes", "com.apple.mail").
    var bundleIdentifier: String { get }

    /// Can the drill run on this Mac right now? Checks for things
    /// like "does Mail have any configured accounts" or "is Notes
    /// on any writable storage".
    func isUsable() async -> UsabilityStatus

    /// Create the surface (a new note / a new compose draft),
    /// populate it with `body`, and return a handle the engine
    /// passes back to `cleanup`. Throws on timeout / scripting error.
    func prepare(body: String) async throws -> PreparedSurface

    /// Delete the surface we created in `prepare`. Best-effort —
    /// callers shouldn't throw if cleanup fails; leftover drafts
    /// will be swept on next app launch by the orphan cleaner.
    func cleanup(_ prepared: PreparedSurface) async
}

enum UsabilityStatus: Sendable, Equatable {
    case ready
    /// App needs setup before it can be used (e.g. Mail with no
    /// accounts). Human-readable reason explains what's missing.
    case needsSetup(reason: String)
    /// App isn't installed / isn't findable. Shouldn't happen for
    /// Apple system apps but we check anyway.
    case missing
}

/// Opaque handle returned by `prepare`. Contains whatever identifier
/// the cleanup step needs (a Notes note id, a Mail draft id, etc.)
/// plus the bundle id so the engine can activate the right app.
struct PreparedSurface: Sendable {
    let bundleIdentifier: String
    let documentIdentifier: String
}

enum ExternalTextSurfaceError: Error, Sendable {
    case scriptingTimedOut
    case scriptingFailed(String)
    case surfaceNotResolved
}
