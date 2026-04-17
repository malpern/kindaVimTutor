import SwiftUI

/// Navigator for the linear step flow. Expands a `Lesson` into `LessonStep`s
/// and exposes forward/backward navigation with animated transitions. Owned
/// per-lesson by `StepCanvasView`.
@Observable
@MainActor
final class LessonStepController {
    private(set) var steps: [LessonStep] = []
    var currentStepIndex: Int = 0
    var navigationDirection: NavigationDirection = .forward

    enum NavigationDirection {
        case forward, backward
    }

    var currentStep: LessonStep? {
        guard currentStepIndex >= 0, currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }

    var stepCount: Int { steps.count }
    var isFirstStep: Bool { currentStepIndex == 0 }
    var isLastStep: Bool { currentStepIndex >= steps.count - 1 }

    var isOnDrillStep: Bool {
        if case .drill = currentStep { return true }
        return false
    }

    func loadLesson(_ lesson: Lesson, chapterTitle: String) {
        steps = LessonStep.steps(from: lesson, chapterTitle: chapterTitle)
        currentStepIndex = 0
        navigationDirection = .forward
    }

    func nextStep() {
        guard !isLastStep else { return }
        navigationDirection = .forward
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStepIndex += 1
        }
    }

    func previousStep() {
        guard !isFirstStep else { return }
        navigationDirection = .backward
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStepIndex -= 1
        }
    }

    func goToStep(_ index: Int) {
        guard index >= 0, index < steps.count else { return }
        navigationDirection = index > currentStepIndex ? .forward : .backward
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStepIndex = index
        }
    }
}
