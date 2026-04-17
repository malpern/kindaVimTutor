import Foundation

/// A completed drill summary: personal-best stats for one exercise.
/// Only the best-performing result is kept (fewest keystrokes, then fastest time).
public struct ExerciseResult: Codable, Sendable {
    public let exerciseId: String
    public let completedAt: Date
    public let timeSeconds: Double
    public let keystrokeCount: Int
    public let attempts: Int
    public let hintsUsed: Int

    public init(exerciseId: String, completedAt: Date, timeSeconds: Double,
                keystrokeCount: Int, attempts: Int, hintsUsed: Int) {
        self.exerciseId = exerciseId
        self.completedAt = completedAt
        self.timeSeconds = timeSeconds
        self.keystrokeCount = keystrokeCount
        self.attempts = attempts
        self.hintsUsed = hintsUsed
    }
}
