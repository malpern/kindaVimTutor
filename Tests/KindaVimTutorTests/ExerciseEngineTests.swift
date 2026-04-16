import Testing
import Foundation
@testable import KindaVimTutor

@Suite("ExerciseEngine lifecycle")
@MainActor
struct ExerciseEngineTests {
    private func deleteWordExercise(drillCount: Int = 2) -> Exercise {
        Exercise(
            id: "t.dw",
            instruction: "delete 'bad '",
            initialText: "bad word",
            initialCursorPosition: 0,
            expectedText: "word",
            expectedCursorPosition: 0,
            hints: [],
            difficulty: .learn,
            drillCount: drillCount
        )
    }

    @Test("starting sets active state and initial counters")
    func startInitializes() {
        let e = ExerciseEngine()
        e.start(deleteWordExercise())
        #expect(e.state == .active)
        #expect(e.completedReps == 0)
        #expect(e.drillCount == 2)
        #expect(e.currentVariation?.expectedText == "word")
        #expect(e.currentSession != nil)
    }

    @Test("matching text advances repCompleted; cursor match is required when specified")
    func completingARepTransitionsState() {
        let e = ExerciseEngine()
        e.start(deleteWordExercise(drillCount: 2))

        // Wrong cursor: no completion.
        e.textDidChange(currentText: "word", cursorPosition: 3)
        #expect(e.state == .active)

        // Right cursor: completion.
        e.textDidChange(currentText: "word", cursorPosition: 0)
        #expect(e.state == .repCompleted)
        #expect(e.completedReps == 1)
    }

    @Test("completing all reps transitions to drillCompleted")
    func drillCompletes() async throws {
        let exercise = Exercise(
            id: "t.one",
            instruction: "",
            initialText: "a",
            initialCursorPosition: 0,
            expectedText: "b",
            expectedCursorPosition: 0,
            hints: [],
            difficulty: .learn,
            drillCount: 1
        )
        let e = ExerciseEngine()
        e.start(exercise)
        e.textDidChange(currentText: "b", cursorPosition: 0)
        #expect(e.state == .drillCompleted)
        #expect(e.currentSession?.completedAt != nil)
    }

    @Test("text without cursor requirement completes on text match alone")
    func cursorAgnosticCompletion() {
        let ex = Exercise(
            id: "t.cursorless",
            instruction: "",
            initialText: "foo",
            initialCursorPosition: 0,
            expectedText: "bar",
            expectedCursorPosition: nil,
            hints: [],
            difficulty: .learn,
            drillCount: 1
        )
        let e = ExerciseEngine()
        e.start(ex)
        e.textDidChange(currentText: "bar", cursorPosition: 99)
        #expect(e.state == .drillCompleted)
    }

    @Test("keystrokeCount increments only while active")
    func keystrokeAccounting() {
        let e = ExerciseEngine()
        e.start(deleteWordExercise(drillCount: 1))
        e.textDidChange(currentText: "wor", cursorPosition: 0)
        e.textDidChange(currentText: "word", cursorPosition: 0) // completes
        #expect(e.completedReps == 1)
        #expect(e.totalKeystrokes > 0)

        // After completion, further text changes should be ignored.
        let after = e.totalKeystrokes
        e.textDidChange(currentText: "anything", cursorPosition: 0)
        #expect(e.totalKeystrokes == after)
    }

    @Test("stop clears state")
    func stopResets() {
        let e = ExerciseEngine()
        e.start(deleteWordExercise())
        e.stop()
        #expect(e.state == .idle)
        #expect(e.exercise == nil)
        #expect(e.currentVariation == nil)
    }

    @Test("drillProgress returns reps/drillCount")
    func drillProgress() {
        let e = ExerciseEngine()
        e.start(deleteWordExercise(drillCount: 4))
        #expect(e.drillProgress == 0)
        e.textDidChange(currentText: "word", cursorPosition: 0)
        #expect(e.drillProgress == 0.25)
    }

    @Test("session records repStarted and repCompleted events")
    func sessionCapturesEvents() {
        let e = ExerciseEngine()
        e.start(deleteWordExercise(drillCount: 1))
        e.textDidChange(currentText: "word", cursorPosition: 0)

        let events = e.currentSession?.events ?? []
        let types = events.map(\.type)
        #expect(types.contains(.repStarted))
        #expect(types.contains(.repCompleted))
        #expect(types.contains(.drillCompleted))

        let rep = e.currentSession?.reps.first
        #expect(rep?.completed == true)
        #expect(rep?.endTimestamp != nil)
    }
}
