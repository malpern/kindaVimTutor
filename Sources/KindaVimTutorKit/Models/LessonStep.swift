import Foundation

/// One slide in the Vimified-style linear flow: a title, a content group,
/// or a drill. `LessonStepController` walks the array produced by `steps(from:)`.
enum LessonStep: Identifiable {
    case title(lesson: Lesson, chapterTitle: String)
    case content(id: String, blocks: [ContentBlock])
    case drill(exercise: Exercise, exerciseNumber: Int)

    var id: String {
        switch self {
        case .title(let lesson, _): "title-\(lesson.id)"
        case .content(let id, _): "content-\(id)"
        case .drill(let exercise, _): "drill-\(exercise.id)"
        }
    }

    /// Convert a lesson into a linear sequence of steps
    static func steps(from lesson: Lesson, chapterTitle: String) -> [LessonStep] {
        var result: [LessonStep] = []

        // 1. Title step
        result.append(.title(lesson: lesson, chapterTitle: chapterTitle))

        // 2. Content steps — group blocks by heading boundaries
        var currentGroup: [ContentBlock] = []
        var groupIndex = 0

        for block in lesson.explanation {
            if case .heading = block, !currentGroup.isEmpty {
                // Flush current group as a step
                result.append(.content(id: "\(lesson.id).c\(groupIndex)", blocks: currentGroup))
                currentGroup = []
                groupIndex += 1
            }
            if case .spacer = block { continue } // Skip spacers between groups
            currentGroup.append(block)
        }
        if !currentGroup.isEmpty {
            result.append(.content(id: "\(lesson.id).c\(groupIndex)", blocks: currentGroup))
        }

        // 3. Drill steps
        for (index, exercise) in lesson.exercises.enumerated() {
            result.append(.drill(exercise: exercise, exerciseNumber: index + 1))
        }

        return result
    }
}
