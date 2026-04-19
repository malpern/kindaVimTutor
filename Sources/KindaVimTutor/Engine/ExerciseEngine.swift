import SwiftUI

@Observable
@MainActor
final class ExerciseEngine {
    enum State: Equatable {
        case idle
        case active
        case repCompleted
        case drillCompleted
    }

    private(set) var state: State = .idle
    private(set) var exercise: Exercise?

    // Current rep
    private(set) var keystrokeCount: Int = 0
    private(set) var elapsedTime: TimeInterval = 0

    // Drill progress
    private(set) var completedReps: Int = 0
    private(set) var drillCount: Int = 5
    private(set) var totalTime: TimeInterval = 0
    private(set) var totalKeystrokes: Int = 0

    // Current variation
    private(set) var currentVariation: Exercise.Variation?

    // Session recording
    private(set) var currentSession: DrillSession?

    // Bumps whenever a reset should force the editor to redraw its content,
    // even if the target initialText string is identical to what was last set.
    private(set) var resetNonce: Int = 0

    private var startTime: Date?
    private var drillStartTime: Date?
    private var timer: Timer?

    var isDrillComplete: Bool { state == .drillCompleted }
    var isRepCompleted: Bool { state == .repCompleted }
    var isActive: Bool { state == .active }

    var drillProgress: Double {
        guard drillCount > 0 else { return 0 }
        return Double(completedReps) / Double(drillCount)
    }

    func start(_ exercise: Exercise) {
        self.exercise = exercise
        self.drillCount = exercise.drillCount
        completedReps = 0
        totalTime = 0
        totalKeystrokes = 0
        drillStartTime = Date()

        // Start a new recording session
        currentSession = DrillSession(exerciseId: exercise.id, drillCount: exercise.drillCount)

        AppLogger.shared.info("drill", "start", fields: [
            "exercise": exercise.id,
            "reps": String(exercise.drillCount)
        ])

        startRep(exercise.variation(for: 0))
    }

    func resetDrill() {
        guard let exercise else { return }
        resetNonce &+= 1
        start(exercise)
    }

    func resetRep() {
        guard let exercise else { return }
        resetNonce &+= 1
        recordEvent(.repReset, text: currentVariation?.initialText ?? "", cursorPosition: 0)
        startRep(exercise.variation(for: completedReps))
    }

    func textDidChange(currentText: String, cursorPosition: Int) {
        guard state == .active else { return }
        keystrokeCount += 1
        recordEvent(.textChanged, text: currentText, cursorPosition: cursorPosition)
        validate(currentText: currentText, cursorPosition: cursorPosition)
    }

    func selectionDidChange(currentText: String, cursorPosition: Int) {
        guard state == .active, let variation = currentVariation else { return }
        if variation.initialText == variation.expectedText {
            keystrokeCount += 1
        }
        recordEvent(.cursorMoved, text: currentText, cursorPosition: cursorPosition)
        validate(currentText: currentText, cursorPosition: cursorPosition)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        state = .idle
        exercise = nil
        currentVariation = nil
    }

    // MARK: - Recording

    private func recordEvent(_ type: DrillSession.Event.EventType, text: String, cursorPosition: Int) {
        guard let drillStartTime else { return }
        let timestamp = Date().timeIntervalSince(drillStartTime)
        let event = DrillSession.Event(
            timestamp: timestamp,
            type: type,
            text: text,
            cursorPosition: cursorPosition,
            repIndex: completedReps
        )
        currentSession?.events.append(event)
    }

    // MARK: - Private

    private func startRep(_ variation: Exercise.Variation) {
        currentVariation = variation
        state = .active
        keystrokeCount = 0
        elapsedTime = 0
        startTime = Date()

        let repTimestamp = drillStartTime.map { Date().timeIntervalSince($0) } ?? 0

        // Record rep start
        currentSession?.reps.append(DrillSession.RepRecord(
            repIndex: completedReps,
            variationText: variation.initialText,
            expectedText: variation.expectedText,
            expectedCursorPosition: variation.expectedCursorPosition,
            startTimestamp: repTimestamp,
            keystrokeCount: 0,
            completed: false
        ))
        recordEvent(.repStarted, text: variation.initialText, cursorPosition: variation.initialCursorPosition)

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let startTime = self.startTime, self.state == .active else { return }
                self.elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
    }

    private func validate(currentText: String, cursorPosition: Int) {
        guard let variation = currentVariation else { return }

        let textMatches = currentText == variation.expectedText
        let cursorMatches: Bool
        if let expectedCursor = variation.expectedCursorPosition {
            cursorMatches = cursorPosition == expectedCursor
        } else {
            cursorMatches = true
        }

        // Diagnostic: log every attempt with byte-level detail so we can
        // compare what the user produced vs what we expected. Filter later
        // with `grep validate ~/Library/Logs/KindaVimTutor/app.log`.
        AppLogger.shared.info("engine", "validate", fields: [
            "textMatch": textMatches ? "1" : "0",
            "cursorMatch": cursorMatches ? "1" : "0",
            "actualLen": String(currentText.count),
            "expectedLen": String(variation.expectedText.count),
            "cursor": String(cursorPosition),
            "expectedCursor": variation.expectedCursorPosition.map(String.init) ?? "nil",
            "actual": currentText,
            "expected": variation.expectedText,
        ])

        if textMatches && cursorMatches {
            completeRep(finalText: currentText, finalCursor: cursorPosition)
        }
    }

    private func completeRep(finalText: String, finalCursor: Int) {
        timer?.invalidate()
        timer = nil

        let repTime = startTime.map { Date().timeIntervalSince($0) } ?? 0
        totalTime += repTime
        totalKeystrokes += keystrokeCount

        // Update rep record
        let repTimestamp = drillStartTime.map { Date().timeIntervalSince($0) } ?? 0
        if let session = currentSession, let lastIndex = session.reps.indices.last {
            var lastRep = session.reps[lastIndex]
            lastRep.endTimestamp = repTimestamp
            lastRep.keystrokeCount = keystrokeCount
            lastRep.completed = true
            currentSession?.reps[lastIndex] = lastRep
        }

        recordEvent(.repCompleted, text: finalText, cursorPosition: finalCursor)
        completedReps += 1

        AppLogger.shared.info("drill", "repCompleted", fields: [
            "exercise": exercise?.id ?? "",
            "rep": String(completedReps),
            "of": String(drillCount),
            "keystrokes": String(keystrokeCount),
            "time": String(format: "%.3f", repTime)
        ])

        if completedReps >= drillCount {
            state = .drillCompleted
            recordEvent(.drillCompleted, text: finalText, cursorPosition: finalCursor)
            currentSession?.completedAt = Date()
            AppLogger.shared.info("drill", "completed", fields: [
                "exercise": exercise?.id ?? "",
                "totalKeystrokes": String(totalKeystrokes),
                "totalTime": String(format: "%.3f", totalTime)
            ])
        } else {
            state = .repCompleted
            guard let exercise else { return }
            let nextVariation = exercise.variation(for: completedReps)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                guard let self, self.state == .repCompleted else { return }
                self.startRep(nextVariation)
            }
        }
    }
}
