import Foundation

/// Session-scoped memory of which one-shot animations have already
/// played. Lets views decide whether to animate fresh or jump to the
/// final state when the student navigates back to a page they've
/// already seen.
///
/// Not persisted — we want the full show again on app relaunch, just
/// not on back-and-forth navigation within a session.
@Observable
@MainActor
final class AnimationReplayTracker {
    static let shared = AnimationReplayTracker()

    private(set) var played: Set<String> = []

    func hasPlayed(_ id: String) -> Bool { played.contains(id) }

    func markPlayed(_ id: String) { played.insert(id) }
}
