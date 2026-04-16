import SwiftUI

@Observable
@MainActor
final class ExerciseInspectorState {
    var isVisible: Bool = false
    var exerciseNumber: Int = 0
    var exerciseId: String = ""

    // Live metrics
    var elapsedTime: TimeInterval = 0
    var keystrokeCount: Int = 0
    var attemptCount: Int = 0
    var isCompleted: Bool = false
    var completedTime: Double = 0
    var completedKeystrokes: Int = 0

    // Best result
    var bestTime: Double?
    var bestKeystrokes: Int?

    // Hints
    var hints: [String] = []
    var showHint: Bool = false

    // Actions
    var onReset: (() -> Void)?

    func show(exerciseNumber: Int, exerciseId: String, hints: [String]) {
        self.exerciseNumber = exerciseNumber
        self.exerciseId = exerciseId
        self.hints = hints
        self.showHint = false
        withAnimation(.easeInOut(duration: 0.2)) {
            isVisible = true
        }
    }

    func hide() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isVisible = false
        }
    }

    func update(engine: ExerciseEngine, bestResult: ExerciseResult?) {
        elapsedTime = engine.elapsedTime
        keystrokeCount = engine.keystrokeCount
        attemptCount = engine.attemptCount
        isCompleted = engine.isCompleted
        if case .completed(let time, let ks) = engine.state {
            completedTime = time
            completedKeystrokes = ks
        }
        bestTime = bestResult?.timeSeconds
        bestKeystrokes = bestResult?.keystrokeCount
    }
}
