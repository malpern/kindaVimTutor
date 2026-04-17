import Testing
@testable import KindaVimTutorKit

@Suite("LessonStep.steps")
struct LessonStepTests {
    private func makeLesson(blocks: [ContentBlock], exerciseCount: Int) -> Lesson {
        let exercises = (0..<exerciseCount).map { i in
            Exercise(
                id: "ex\(i)",
                instruction: "",
                initialText: "a",
                initialCursorPosition: 0,
                expectedText: "b",
                expectedCursorPosition: nil,
                hints: [],
                difficulty: .learn
            )
        }
        return Lesson(
            id: "l1",
            number: 1,
            title: "Test lesson",
            subtitle: "",
            explanation: blocks,
            exercises: exercises,
            motionsIntroduced: []
        )
    }

    @Test("title + single content + drills")
    func simpleLesson() {
        let lesson = makeLesson(blocks: [.text("hello")], exerciseCount: 2)
        let steps = LessonStep.steps(from: lesson, chapterTitle: "Chapter X")
        #expect(steps.count == 4) // title + 1 content + 2 drills
        if case .title = steps[0] {} else { Issue.record("expected title at 0") }
        if case .content = steps[1] {} else { Issue.record("expected content at 1") }
        if case .drill = steps[2] {} else { Issue.record("expected drill at 2") }
        if case .drill = steps[3] {} else { Issue.record("expected drill at 3") }
    }

    @Test("headings split content into multiple steps")
    func headingsSplit() {
        let lesson = makeLesson(blocks: [
            .heading("Intro"),
            .text("paragraph 1"),
            .heading("Next"),
            .text("paragraph 2")
        ], exerciseCount: 0)
        let steps = LessonStep.steps(from: lesson, chapterTitle: "c")
        // title + 2 content groups
        #expect(steps.count == 3)
    }

    @Test("spacers are dropped but content groups persist")
    func spacersDropped() {
        let lesson = makeLesson(blocks: [
            .text("one"),
            .spacer,
            .text("two")
        ], exerciseCount: 0)
        let steps = LessonStep.steps(from: lesson, chapterTitle: "c")
        // title + 1 content group
        #expect(steps.count == 2)
        if case .content(_, let blocks) = steps[1] {
            #expect(blocks.count == 2)
            for block in blocks {
                if case .spacer = block { Issue.record("spacer should have been dropped") }
            }
        } else {
            Issue.record("expected content step")
        }
    }

    @Test("step ids are stable and unique within a lesson")
    func stepIdsUnique() {
        let lesson = makeLesson(blocks: [
            .heading("a"), .text("x"),
            .heading("b"), .text("y")
        ], exerciseCount: 2)
        let steps = LessonStep.steps(from: lesson, chapterTitle: "c")
        let ids = Set(steps.map(\.id))
        #expect(ids.count == steps.count)
    }
}
