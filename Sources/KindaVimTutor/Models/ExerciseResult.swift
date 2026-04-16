import Foundation

struct ExerciseResult: Codable, Sendable {
    let exerciseId: String
    let completedAt: Date
    let timeSeconds: Double
    let keystrokeCount: Int
    let attempts: Int
    let hintsUsed: Int
}
