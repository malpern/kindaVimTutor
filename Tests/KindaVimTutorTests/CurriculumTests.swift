import Testing
@testable import KindaVimTutorKit

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
}
