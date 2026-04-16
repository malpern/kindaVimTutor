import SwiftUI

@Observable
@MainActor
final class ExerciseEngine {
    enum State: Equatable {
        case idle
        case active
        case repCompleted   // brief pause before next rep
        case drillCompleted // all reps done
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

    private var startTime: Date?
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
        startRep(exercise.variation(for: 0))
    }

    func resetDrill() {
        guard let exercise else { return }
        start(exercise)
    }

    func resetRep() {
        guard let exercise else { return }
        startRep(exercise.variation(for: completedReps))
    }

    func textDidChange(currentText: String, cursorPosition: Int) {
        guard state == .active else { return }
        keystrokeCount += 1
        validate(currentText: currentText, cursorPosition: cursorPosition)
    }

    func selectionDidChange(currentText: String, cursorPosition: Int) {
        guard state == .active, let variation = currentVariation else { return }
        // For cursor-only exercises, count selection changes
        if variation.initialText == variation.expectedText {
            keystrokeCount += 1
        }
        validate(currentText: currentText, cursorPosition: cursorPosition)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        state = .idle
        exercise = nil
        currentVariation = nil
    }

    // MARK: - Private

    private func startRep(_ variation: Exercise.Variation) {
        currentVariation = variation
        state = .active
        keystrokeCount = 0
        elapsedTime = 0
        startTime = Date()

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

        if textMatches && cursorMatches {
            completeRep()
        }
    }

    private func completeRep() {
        timer?.invalidate()
        timer = nil

        let repTime = startTime.map { Date().timeIntervalSince($0) } ?? 0
        totalTime += repTime
        totalKeystrokes += keystrokeCount
        completedReps += 1

        if completedReps >= drillCount {
            state = .drillCompleted
        } else {
            state = .repCompleted
            // Auto-advance to next rep after brief pause
            guard let exercise else { return }
            let nextVariation = exercise.variation(for: completedReps)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                guard let self, self.state == .repCompleted else { return }
                self.startRep(nextVariation)
            }
        }
    }
}
