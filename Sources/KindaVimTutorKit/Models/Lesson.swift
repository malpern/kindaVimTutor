import Foundation

/// A single lesson: explanatory content + a set of drill exercises.
/// Converted into a linear `[LessonStep]` sequence by `LessonStep.steps(from:)`
/// for presentation inside `StepCanvasView`.
public struct Lesson: Identifiable, Hashable, Sendable {
    public static func == (lhs: Lesson, rhs: Lesson) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }

    public let id: String
    public let number: Int
    public let title: String
    public let subtitle: String
    public let explanation: [ContentBlock]
    public let exercises: [Exercise]
    public let motionsIntroduced: [String]

    public init(id: String, number: Int, title: String, subtitle: String,
                explanation: [ContentBlock], exercises: [Exercise], motionsIntroduced: [String]) {
        self.id = id
        self.number = number
        self.title = title
        self.subtitle = subtitle
        self.explanation = explanation
        self.exercises = exercises
        self.motionsIntroduced = motionsIntroduced
    }
}
