import Foundation
import Observation

/// Session-scoped preference for whether the DrillCoachingView opens
/// with its Details panel pre-expanded. Flips to `true` the first
/// time the student opens Details on any drill. Resets on relaunch
/// so the default stays simple for new sessions.
@Observable
@MainActor
final class DrillCoachingPreferences {
    static let shared = DrillCoachingPreferences()
    var autoExpandDetails: Bool = false
}
