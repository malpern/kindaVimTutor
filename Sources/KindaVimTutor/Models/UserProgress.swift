import Foundation

struct UserProgress: Codable, Sendable {
    var completedExercises: [String: ExerciseResult] = [:]
    var currentLessonId: String?
    var totalTimeSpent: TimeInterval = 0
    var lastPracticeDate: Date?
}
