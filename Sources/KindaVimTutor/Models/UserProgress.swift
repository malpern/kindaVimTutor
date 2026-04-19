import Foundation

struct UserProgress: Codable, Sendable {
    var completedExercises: [String: ExerciseResult] = [:]
    var currentLessonId: String?
    var totalTimeSpent: TimeInterval = 0
    var lastPracticeDate: Date?
    // Set when the user chooses "Start Over" in Settings. Exercises with
    // completedAt <= this date are preserved for historic stats but no
    // longer count toward current tutor progress.
    var startedOverAt: Date?
}
