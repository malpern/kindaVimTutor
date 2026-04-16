import SwiftUI

@Observable
@MainActor
final class ExerciseEngine {
    enum State: Equatable {
        case idle
        case active
        case completed(timeSeconds: Double, keystrokeCount: Int)
    }

    private(set) var state: State = .idle
    private(set) var keystrokeCount: Int = 0
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var currentHintIndex: Int = -1
    private(set) var attemptCount: Int = 0

    var exercise: Exercise?
    private var startTime: Date?
    private var timer: Timer?

    var isCompleted: Bool {
        if case .completed = state { return true }
        return false
    }

    func start(_ exercise: Exercise) {
        let isNewExercise = self.exercise?.id != exercise.id
        self.exercise = exercise
        state = .active
        keystrokeCount = 0
        elapsedTime = 0
        currentHintIndex = -1
        startTime = Date()
        if isNewExercise {
            attemptCount = 1
        }

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let startTime = self.startTime else { return }
                self.elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
    }

    func reset() {
        guard exercise != nil else { return }
        attemptCount += 1
        state = .active
        keystrokeCount = 0
        elapsedTime = 0
        currentHintIndex = -1
        startTime = Date()

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let startTime = self.startTime else { return }
                self.elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
    }

    func showNextHint() {
        guard let exercise else { return }
        if currentHintIndex < exercise.hints.count - 1 {
            currentHintIndex += 1
        }
    }

    func textDidChange(currentText: String, cursorPosition: Int) {
        guard case .active = state else { return }
        keystrokeCount += 1
        validate(currentText: currentText, cursorPosition: cursorPosition)
    }

    func selectionDidChange(currentText: String, cursorPosition: Int) {
        guard case .active = state, let exercise else { return }
        // For cursor-only exercises (text doesn't change), count selection changes
        if exercise.initialText == exercise.expectedText {
            keystrokeCount += 1
        }
        validate(currentText: currentText, cursorPosition: cursorPosition)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        state = .idle
        exercise = nil
    }

    private func validate(currentText: String, cursorPosition: Int) {
        guard let exercise else { return }

        let textMatches = currentText == exercise.expectedText
        let cursorMatches: Bool
        if let expectedCursor = exercise.expectedCursorPosition {
            cursorMatches = cursorPosition == expectedCursor
        } else {
            cursorMatches = true
        }

        if textMatches && cursorMatches {
            timer?.invalidate()
            timer = nil
            let time = startTime.map { Date().timeIntervalSince($0) } ?? 0
            state = .completed(timeSeconds: time, keystrokeCount: keystrokeCount)
        }
    }
}
