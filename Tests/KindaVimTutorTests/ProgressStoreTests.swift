import Testing
import Foundation
@testable import KindaVimTutor

@Suite("ProgressStore persistence and bookkeeping")
@MainActor
struct ProgressStoreTests {
    @Test("recording a result persists it and isExerciseCompleted reports true")
    func recordAndQuery() {
        let store = ProgressStore()
        let id = "test.record.\(UUID().uuidString.prefix(6))"
        let result = ExerciseResult(
            exerciseId: id,
            completedAt: Date(),
            timeSeconds: 12.3,
            keystrokeCount: 4,
            attempts: 1,
            hintsUsed: 0
        )
        store.recordCompletion(result)
        #expect(store.isExerciseCompleted(id))
        #expect(store.bestResult(for: id)?.keystrokeCount == 4)
    }

    @Test("recordCompletion keeps the result with fewer keystrokes")
    func keepsBestResult() {
        let store = ProgressStore()
        let id = "test.best.\(UUID().uuidString.prefix(6))"
        let worse = ExerciseResult(exerciseId: id, completedAt: Date(), timeSeconds: 5, keystrokeCount: 10, attempts: 1, hintsUsed: 0)
        let better = ExerciseResult(exerciseId: id, completedAt: Date(), timeSeconds: 5, keystrokeCount: 4, attempts: 1, hintsUsed: 0)
        store.recordCompletion(worse)
        store.recordCompletion(better)
        #expect(store.bestResult(for: id)?.keystrokeCount == 4)

        // Further worse result does not overwrite.
        let muchWorse = ExerciseResult(exerciseId: id, completedAt: Date(), timeSeconds: 5, keystrokeCount: 100, attempts: 1, hintsUsed: 0)
        store.recordCompletion(muchWorse)
        #expect(store.bestResult(for: id)?.keystrokeCount == 4)
    }

    @Test("lessonProgress is the fraction of exercises completed")
    func lessonProgressFraction() {
        let store = ProgressStore()
        let tag = UUID().uuidString.prefix(6)
        let exercises = (0..<4).map { i in
            Exercise(id: "lp.\(tag).\(i)", instruction: "", initialText: "a",
                     initialCursorPosition: 0, expectedText: "b",
                     expectedCursorPosition: nil, hints: [], difficulty: .learn)
        }
        let lesson = Lesson(id: "lp.\(tag)", number: 1, title: "t", subtitle: "",
                            explanation: [], exercises: exercises, motionsIntroduced: [])

        #expect(store.lessonProgress(lesson) == 0)

        for ex in exercises.prefix(2) {
            store.recordCompletion(ExerciseResult(exerciseId: ex.id, completedAt: Date(),
                                                   timeSeconds: 1, keystrokeCount: 1,
                                                   attempts: 1, hintsUsed: 0))
        }
        #expect(store.lessonProgress(lesson) == 0.5)
    }

    @Test("saveDrillSession writes a JSON file under sessions/")
    func saveDrillSessionWritesFile() throws {
        let store = ProgressStore()
        var session = DrillSession(exerciseId: "ds.\(UUID().uuidString.prefix(6))", drillCount: 1)
        session.events.append(.init(timestamp: 0, type: .repStarted, text: "a", cursorPosition: 0, repIndex: 0))
        session.completedAt = Date()
        store.saveDrillSession(session)

        let sessionsDir = store.progressFileURL.deletingLastPathComponent().appendingPathComponent("sessions", isDirectory: true)
        let contents = (try? FileManager.default.contentsOfDirectory(atPath: sessionsDir.path)) ?? []
        #expect(contents.contains { $0.contains(session.exerciseId) })
    }
}
