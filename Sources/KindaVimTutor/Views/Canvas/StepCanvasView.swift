import SwiftUI

struct StepCanvasView: View {
    let lesson: Lesson
    let chapterTitle: String
    let progressStore: ProgressStore
    let inspectorState: ExerciseInspectorState
    var onNextLesson: (() -> Void)?

    @State private var controller = LessonStepController()
    @State private var isEditorFocused = false
    @FocusState private var canvasFocused: Bool

    var body: some View {
        ZStack {
            // Current step content
            if let step = controller.currentStep {
                Group {
                    switch step {
                    case .title(let lesson, let chapterTitle):
                        TitleStepView(lesson: lesson, chapterTitle: chapterTitle)

                    case .content(_, let blocks):
                        ContentStepView(blocks: blocks, onAutoAdvance: advanceForward)

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
        .focused($canvasFocused)
        .accessibilityIdentifier("StepCanvas")
        .accessibilityLabel(accessibilityStatus)
        .onAppear {
            controller.loadLesson(lesson, chapterTitle: chapterTitle)
            AppCommandChannel.shared.registerController(controller)
            canvasFocused = true
        }
        .onChange(of: lesson) {
            controller.loadLesson(lesson, chapterTitle: chapterTitle)
            isEditorFocused = false
            AppCommandChannel.shared.registerController(controller)
            canvasFocused = true
        }
        .onChange(of: controller.currentStepIndex) {
            AppCommandChannel.shared.notifyStateChanged()
            // On non-drill steps (content/title), canvas needs focus so l/h work.
            // On drill steps, editor grabs focus itself via isActive.
            if !controller.isOnDrillStep {
                canvasFocused = true
            }
        }
        .onChange(of: isEditorFocused) { _, focused in
            // When the editor resigns (e.g., drill complete), pull keyboard focus
            // back so `l` advances without a manual click.
            if !focused {
                canvasFocused = true
            }
        }
        .onDisappear {
            AppCommandChannel.shared.registerController(nil)
        }
        .onKeyPress { keyPress in
            handleKeyPress(keyPress)
        }
    }

    // MARK: - Key handling

    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        let char = keyPress.characters.first

        // Page navigation: ] = forward, [ = back, Space = forward.
        // (Using [ and ] so they don't collide with hjkl exercise keys.)
        switch char {
        case "]", " ":
            if canNavigateForward {
                advanceForward()
                return .handled
            }
            return .ignored

        case "[":
            if canNavigateBackward {
                controller.previousStep()
                return .handled
            }
            return .ignored

        default:
            return .ignored
        }
    }

    /// Advances within the lesson, or jumps to the next lesson when on the last step.
    private func advanceForward() {
        if controller.isLastStep {
            onNextLesson?()
        } else {
            controller.nextStep()
        }
    }

    /// Can navigate forward? Not when editor is focused with an incomplete drill.
    /// On the last step, we advance to the next lesson instead (if one exists).
    private var canNavigateForward: Bool {
        if controller.isOnDrillStep && isEditorFocused {
            if case .drill(let exercise, _) = controller.currentStep {
                return progressStore.isExerciseCompleted(exercise.id)
            }
            return false
        }
        if controller.isLastStep {
            return onNextLesson != nil
        }
        return true
    }

    /// Can navigate backward? Not when editor is focused
    private var canNavigateBackward: Bool {
        if controller.isOnDrillStep && isEditorFocused {
            return false
        }
        return !controller.isFirstStep
    }

    private var accessibilityStatus: String {
        let step = controller.currentStep
        let stepKind: String
        let stepId: String
        switch step {
        case .title(let lesson, _):
            stepKind = "title"; stepId = lesson.id
        case .content(let id, _):
            stepKind = "content"; stepId = id
        case .drill(let exercise, _):
            stepKind = "drill"; stepId = exercise.id
        case .none:
            stepKind = "none"; stepId = ""
        }
        return "step=\(stepKind) id=\(stepId) index=\(controller.currentStepIndex + 1)/\(controller.stepCount) lesson=\(lesson.id) focused=\(isEditorFocused ? "1" : "0")"
    }

    private var stepTransition: AnyTransition {
        let forward = controller.navigationDirection == .forward
        return .asymmetric(
            insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)
        )
    }
}
