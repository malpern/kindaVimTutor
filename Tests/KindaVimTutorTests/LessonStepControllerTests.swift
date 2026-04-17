import Testing
@testable import KindaVimTutorKit

@Suite("LessonStepController navigation")
@MainActor
struct LessonStepControllerTests {
    private func sampleLesson() -> Lesson {
        let ex = Exercise(
            id: "e1", instruction: "", initialText: "a",
            initialCursorPosition: 0, expectedText: "b",
            expectedCursorPosition: nil, hints: [], difficulty: .learn
        )
        return Lesson(
            id: "lsn",
            number: 1,
            title: "t",
            subtitle: "",
            explanation: [.text("one")],
            exercises: [ex],
            motionsIntroduced: []
        )
    }

    @Test("loading a lesson sets index to 0 and direction forward")
    func loadResets() {
        let c = LessonStepController()
        c.loadLesson(sampleLesson(), chapterTitle: "c")
        #expect(c.currentStepIndex == 0)
        #expect(c.isFirstStep)
        #expect(c.stepCount == 3)
    }

    @Test("nextStep advances and previousStep goes back")
    func nextPrev() {
        let c = LessonStepController()
        c.loadLesson(sampleLesson(), chapterTitle: "c")

        c.nextStep()
        #expect(c.currentStepIndex == 1)
        #expect(c.navigationDirection == .forward)

        c.previousStep()
        #expect(c.currentStepIndex == 0)
        #expect(c.navigationDirection == .backward)
    }

    @Test("nextStep is a no-op on the last step")
    func nextClampsAtEnd() {
        let c = LessonStepController()
        c.loadLesson(sampleLesson(), chapterTitle: "c")
        c.nextStep(); c.nextStep(); c.nextStep() // stepCount is 3
        #expect(c.isLastStep)
        let before = c.currentStepIndex
        c.nextStep()
        #expect(c.currentStepIndex == before)
    }

    @Test("previousStep is a no-op on the first step")
    func prevClampsAtStart() {
        let c = LessonStepController()
        c.loadLesson(sampleLesson(), chapterTitle: "c")
        c.previousStep()
        #expect(c.currentStepIndex == 0)
    }

    @Test("isOnDrillStep is true only for drill steps")
    func isOnDrill() {
        let c = LessonStepController()
        c.loadLesson(sampleLesson(), chapterTitle: "c")
        #expect(c.isOnDrillStep == false) // title
        c.nextStep()
        #expect(c.isOnDrillStep == false) // content
        c.nextStep()
        #expect(c.isOnDrillStep == true)  // drill
    }

    @Test("goToStep rejects out-of-range indices")
    func goToStepBounds() {
        let c = LessonStepController()
        c.loadLesson(sampleLesson(), chapterTitle: "c")
        c.goToStep(-1)
        #expect(c.currentStepIndex == 0)
        c.goToStep(999)
        #expect(c.currentStepIndex == 0)
    }
}
