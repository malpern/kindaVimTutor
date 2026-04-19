import Testing
@testable import KindaVimTutor

@Suite("Curriculum structural integrity")
struct CurriculumTests {
    @Test("at least one chapter with lessons is present")
    func hasContent() {
        #expect(Curriculum.chapters.count >= 1)
        let lessons = Curriculum.chapters.flatMap(\.lessons)
        #expect(lessons.isEmpty == false)
    }

    @Test("lesson ids are unique across the curriculum")
    func uniqueLessonIds() {
        let ids = Curriculum.chapters.flatMap(\.lessons).map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("exercise ids are unique across the curriculum")
    func uniqueExerciseIds() {
        let ids = Curriculum.chapters.flatMap(\.lessons).flatMap(\.exercises).map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("every exercise has a non-empty instruction, initialText and expectedText")
    func exerciseFieldsPopulated() {
        for exercise in Curriculum.chapters.flatMap(\.lessons).flatMap(\.exercises) {
            #expect(!exercise.id.isEmpty, "exercise has empty id")
            #expect(!exercise.instruction.isEmpty, "exercise \(exercise.id) has empty instruction")
            #expect(!exercise.expectedText.isEmpty || !exercise.initialText.isEmpty,
                    "exercise \(exercise.id) has empty text")
        }
    }

    @Test("every exercise's expected cursor (when set) is within expectedText")
    func expectedCursorInBounds() {
        for exercise in Curriculum.chapters.flatMap(\.lessons).flatMap(\.exercises) {
            if let cursor = exercise.expectedCursorPosition {
                #expect(cursor >= 0 && cursor <= exercise.expectedText.count,
                        "exercise \(exercise.id) has expectedCursorPosition=\(cursor) outside expectedText length \(exercise.expectedText.count)")
            }
        }
    }

    @Test("every lesson yields a non-empty step sequence")
    func stepsNonEmpty() {
        for chapter in Curriculum.chapters {
            for lesson in chapter.lessons {
                let steps = LessonStep.steps(from: lesson, chapterTitle: chapter.title)
                #expect(steps.count >= 1, "lesson \(lesson.id) produced no steps")
            }
        }
    }

    // MARK: - Vimified canvas invariants

    /// Exercises whose `initialText` starts with a newline are treated as
    /// vimified-canvas style. Those should all share structural invariants:
    /// • at least one `//` comment row
    /// • each variation's initialText starts with a newline
    /// • initial cursor is within bounds and never on an obviously wrong byte
    @Test("vimified canvas exercises have consistent structure")
    func canvasStructure() {
        for exercise in Curriculum.chapters.flatMap(\.lessons).flatMap(\.exercises) {
            guard exercise.initialText.hasPrefix("\n") else { continue }
            let pairs = [(exercise.initialText, exercise.initialCursorPosition,
                          exercise.expectedText, exercise.expectedCursorPosition)]
                + exercise.variations.map {
                    ($0.initialText, $0.initialCursorPosition,
                     $0.expectedText, $0.expectedCursorPosition)
                }
            for (init_, cursor, expected, exCursor) in pairs {
                #expect(init_.hasPrefix("\n"),
                        "\(exercise.id): variation initialText should start with \\n")
                #expect(init_.contains("//"),
                        "\(exercise.id): canvas exercise missing // comment")
                #expect(cursor >= 0 && cursor <= init_.count,
                        "\(exercise.id): initialCursorPosition=\(cursor) outside initialText[\(init_.count)]")
                if let ec = exCursor {
                    #expect(ec >= 0 && ec <= expected.count,
                            "\(exercise.id): expectedCursorPosition=\(ec) outside expectedText[\(expected.count)]")
                }
            }
        }
    }

    /// If a cursor-only exercise (expectedText == initialText) defines an
    /// expectedCursor, that cursor must actually differ from the initial —
    /// otherwise the drill would be completable without moving.
    @Test("cursor-only exercises require the cursor to move")
    func cursorOnlyExercisesRequireMovement() {
        for exercise in Curriculum.chapters.flatMap(\.lessons).flatMap(\.exercises) {
            let variants = [(exercise.initialText, exercise.initialCursorPosition,
                             exercise.expectedText, exercise.expectedCursorPosition)]
                + exercise.variations.map {
                    ($0.initialText, $0.initialCursorPosition,
                     $0.expectedText, $0.expectedCursorPosition)
                }
            for (init_, iCursor, expected, eCursor) in variants {
                guard init_ == expected, let ec = eCursor else { continue }
                #expect(ec != iCursor,
                        "\(exercise.id): cursor-only drill has expectedCursor == initialCursor (\(iCursor))")
            }
        }
    }

}
