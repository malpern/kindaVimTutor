import Foundation

/// A complete recording of a drill session, suitable for LLM analysis.
/// Captures the full event stream so an LLM can replay the editing trajectory,
/// identify errors, assess fluency, and suggest better motions.
struct DrillSession: Codable, Sendable {
    let id: UUID
    let exerciseId: String
    let drillCount: Int
    let startedAt: Date
    var completedAt: Date?
    var events: [Event]
    var reps: [RepRecord]

    struct Event: Codable, Sendable {
        let timestamp: TimeInterval   // seconds since drill start
        let type: EventType
        let text: String              // full text state after this event
        let cursorPosition: Int
        let repIndex: Int             // which rep (0-based)

        enum EventType: String, Codable, Sendable {
            case textChanged        // text was modified (insert, delete, etc.)
            case cursorMoved        // cursor/selection changed without text change
            case repStarted         // new rep began (includes initial text state)
            case repCompleted       // user reached the expected state
            case repReset           // user manually reset the current rep
            case drillCompleted     // all reps finished
        }
    }

    struct RepRecord: Codable, Sendable {
        let repIndex: Int
        let variationText: String         // the initial text for this rep
        let expectedText: String          // what success looks like
        let expectedCursorPosition: Int?
        let startTimestamp: TimeInterval
        var endTimestamp: TimeInterval?
        var keystrokeCount: Int
        var completed: Bool
    }

    init(exerciseId: String, drillCount: Int) {
        self.id = UUID()
        self.exerciseId = exerciseId
        self.drillCount = drillCount
        self.startedAt = Date()
        self.events = []
        self.reps = []
    }
}
