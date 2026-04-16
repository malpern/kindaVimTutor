import SwiftUI

struct StepCanvasView: View {
    let lesson: Lesson
    let chapterTitle: String
    let progressStore: ProgressStore
    let inspectorState: ExerciseInspectorState
    var onNextLesson: (() -> Void)?

    @State private var controller = LessonStepController()
    @State private var isEditorFocused = false

    var body: some View {
        ZStack {
            // Current step content
            if let step = controller.currentStep {
                Group {
                    switch step {
                    case .title(let lesson, let chapterTitle):
                        TitleStepView(lesson: lesson, chapterTitle: chapterTitle)

                    case .content(_, let blocks):
                        ContentStepView(blocks: blocks)

                    case .drill(let exercise, let exerciseNumber):
                        DrillStepView(
                            exercise: exercise,
                            exerciseNumber: exerciseNumber,
                            progressStore: progressStore,
                            inspectorState: inspectorState,
                            isEditorFocused: $isEditorFocused
                        )
                    }
                }
                .id(step.id)
                .transition(stepTransition)
            }

            // Step indicator at bottom
            VStack {
                Spacer()
                StepIndicatorView(
                    stepCount: controller.stepCount,
                    currentIndex: controller.currentStepIndex
                )
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .focusable()
        .onAppear {
            controller.loadLesson(lesson, chapterTitle: chapterTitle)
        }
        .onChange(of: lesson) {
            controller.loadLesson(lesson, chapterTitle: chapterTitle)
            isEditorFocused = false
        }
        .onKeyPress { keyPress in
            handleKeyPress(keyPress)
        }
    }

    // MARK: - Key handling

    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        let char = keyPress.characters.first

        // Vim navigation: l = forward, h = back, Space = forward
        switch char {
        case "l", " ":
            if canNavigateForward {
                controller.nextStep()
                return .handled
            }
            return .ignored

        case "h":
            if canNavigateBackward {
                controller.previousStep()
                return .handled
            }
            return .ignored

        default:
            return .ignored
        }
    }

    /// Can navigate forward? Not when editor is focused (keys go to kindaVim)
    private var canNavigateForward: Bool {
        if controller.isOnDrillStep && isEditorFocused {
            if case .drill(let exercise, _) = controller.currentStep {
                return progressStore.isExerciseCompleted(exercise.id)
            }
            return false
        }
        return !controller.isLastStep
    }

    /// Can navigate backward? Not when editor is focused
    private var canNavigateBackward: Bool {
        if controller.isOnDrillStep && isEditorFocused {
            return false
        }
        return !controller.isFirstStep
    }

    private var stepTransition: AnyTransition {
        let forward = controller.navigationDirection == .forward
        return .asymmetric(
            insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)
        )
    }
}
