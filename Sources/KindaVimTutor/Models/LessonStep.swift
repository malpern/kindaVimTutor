import Foundation

enum LessonStep: Identifiable {
    case title(lesson: Lesson, chapterTitle: String)
    case content(id: String, blocks: [ContentBlock])
    case drill(exercise: Exercise, exerciseNumber: Int)
    case modeSequence(id: String, step: InteractiveStep)
    case finderDrill(id: String, spec: FinderDrillSpec)

    var id: String {
        switch self {
        case .title(let lesson, _): "title-\(lesson.id)"
        case .content(let id, _): "content-\(id)"
        case .drill(let exercise, _): "drill-\(exercise.id)"
        case .modeSequence(let id, _): "modeseq-\(id)"
        case .finderDrill(let id, _): "finderdrill-\(id)"
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
            // Either a heading or a modeIndicatorSpotlight forces a
            // step break so the spotlight gets its own full page.
            let forcesBreak: Bool = {
                if case .heading = block { return true }
                if case .modeIndicatorSpotlight = block { return true }
                return false
            }()
            if forcesBreak, !currentGroup.isEmpty {
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

        // 3. Interactive step (e.g. mode sequence), placed before drills
        if let interactive = lesson.interactive {
            result.append(.modeSequence(id: lesson.id, step: interactive))
        }

        // 4. Drill steps
        for (index, exercise) in lesson.exercises.enumerated() {
            result.append(.drill(exercise: exercise, exerciseNumber: index + 1))
        }

        // 5. Finder drill (if any). Comes after the editor drills —
        // the student practices in the editor first, then in the
        // system Finder.
        if let spec = lesson.finderDrill {
            result.append(.finderDrill(id: lesson.id, spec: spec))
        }

        return result
    }
}

/// Description of a Finder-navigation drill as authored in the
/// curriculum. Converts to a FinderDrillEngine.Rep list at run time.
struct FinderDrillSpec: Hashable, Sendable {
    struct Rep: Hashable, Sendable {
        let start: String
        let target: String
    }
    let title: String
    let subtitle: String
    let reps: [Rep]
}
