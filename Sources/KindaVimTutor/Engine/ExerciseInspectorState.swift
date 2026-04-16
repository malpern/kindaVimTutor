import SwiftUI

@Observable
@MainActor
final class ExerciseInspectorState {
    var isVisible: Bool = false
    var exerciseNumber: Int = 0
    var exerciseId: String = ""

    // Drill progress
    var completedReps: Int = 0
    var drillCount: Int = 5
    var drillProgress: Double = 0
    var isDrillComplete: Bool = false

    // Current rep metrics
    var elapsedTime: TimeInterval = 0
    var keystrokeCount: Int = 0

    // Accumulated totals
    var totalTime: TimeInterval = 0
    var totalKeystrokes: Int = 0

    // Best result
    var bestTime: Double?
    var bestKeystrokes: Int?

    // Hints
    var hints: [String] = []
    var showHint: Bool = false

    // Actions
    var onResetRep: (() -> Void)?
    var onResetDrill: (() -> Void)?

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
        completedReps = engine.completedReps
        drillCount = engine.drillCount
        drillProgress = engine.drillProgress
        isDrillComplete = engine.isDrillComplete
        elapsedTime = engine.elapsedTime
        keystrokeCount = engine.keystrokeCount
        totalTime = engine.totalTime
        totalKeystrokes = engine.totalKeystrokes
        bestTime = bestResult?.timeSeconds
        bestKeystrokes = bestResult?.keystrokeCount
    }
}
