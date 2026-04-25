import SwiftUI

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

    /// The lesson this controller currently has steps for. Lets
    /// `loadLesson` be a no-op when SwiftUI re-runs `.onAppear`
    /// after a window-activation cycle (e.g. the user switching to
    /// Bear and back) — without this guard the step index resets to
    /// 0, throwing the student back to the lesson intro mid-drill.
    private var loadedLessonID: String?

    func loadLesson(_ lesson: Lesson, chapterTitle: String) {
        if loadedLessonID == lesson.id {
            AppLogger.shared.info("step", "loadLessonSkipped", fields: [
                "lesson": lesson.id,
                "currentIndex": String(currentStepIndex),
            ])
            return
        }
        steps = LessonStep.steps(from: lesson, chapterTitle: chapterTitle)
        currentStepIndex = 0
        navigationDirection = .forward
        loadedLessonID = lesson.id
        AppLogger.shared.info("step", "loadLesson", fields: [
            "lesson": lesson.id,
            "chapter": chapterTitle,
            "stepCount": String(steps.count)
        ])
    }

    func nextStep() {
        guard !isLastStep else { return }
        navigationDirection = .forward
        // Intentionally no `withAnimation` here. SwiftUI's
        // `withAnimation` applies to every observable state change
        // inside the transaction, including sidebar layout — which
        // caused the rail to jitter / scroll-reset on every step
        // advance. The step-container in StepCanvasView has a
        // scoped `.animation(.easeInOut, value: currentStepIndex)`
        // that drives the transition.
        currentStepIndex += 1
        logCurrentStep("next")
    }

    func previousStep() {
        guard !isFirstStep else { return }
        navigationDirection = .backward
        currentStepIndex -= 1
        logCurrentStep("previous")
    }

    func goToStep(_ index: Int) {
        guard index >= 0, index < steps.count else { return }
        navigationDirection = index > currentStepIndex ? .forward : .backward
        currentStepIndex = index
        logCurrentStep("goTo")
    }

    private func logCurrentStep(_ reason: String) {
        AppLogger.shared.info("step", "change", fields: [
            "reason": reason,
            "index": String(currentStepIndex),
            "total": String(steps.count),
            "id": currentStep?.id ?? ""
        ])
    }
}
