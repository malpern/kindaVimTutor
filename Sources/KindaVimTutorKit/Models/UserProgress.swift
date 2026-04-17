import Foundation

/// Persisted user state. Written to `~/Library/Application Support/kindaVimTutor/progress.json`
/// by `ProgressStore`. Keyed by exercise id; only the best result per exercise is retained.
public struct UserProgress: Codable, Sendable {
    public var completedExercises: [String: ExerciseResult] = [:]
    public var currentLessonId: String?
    public var totalTimeSpent: TimeInterval = 0
    public var lastPracticeDate: Date?

    public init() {}
}
