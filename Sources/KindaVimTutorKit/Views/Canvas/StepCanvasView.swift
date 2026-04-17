import SwiftUI

/// The detail pane. Renders one `LessonStep` at a time (title → content →
/// drills) and routes `h`/`l`/`space` key presses to the step controller.
/// Forward navigation on a drill step is gated on completion so the user
/// must finish a drill before moving on.
public struct StepCanvasView: View {
    let lesson: Lesson
    let chapterTitle: String
    let progressStore: ProgressStore
    /// Optional step to jump to on first appear. Used by the screenshot
    /// harness to land on a specific slide without user interaction.
    let initialStepIndex: Int?
    var onNextLesson: (() -> Void)?

    @State private var controller = LessonStepController()
    @State private var isEditorFocused = false

    public init(lesson: Lesson, chapterTitle: String, progressStore: ProgressStore, initialStepIndex: Int? = nil, onNextLesson: (() -> Void)? = nil) {
        self.lesson = lesson
        self.chapterTitle = chapterTitle
        self.progressStore = progressStore
        self.initialStepIndex = initialStepIndex
        self.onNextLesson = onNextLesson
    }

    public var body: some View {
        ZStack {
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
                            isEditorFocused: $isEditorFocused
                        )
                    }
                }
                .id(step.id)
                .transition(stepTransition)
            }

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
            if let idx = initialStepIndex {
                controller.goToStep(idx)
            }
        }
        .onChange(of: lesson) {
            controller.loadLesson(lesson, chapterTitle: chapterTitle)
            isEditorFocused = false
        }
        .onKeyPress { keyPress in
            handleKeyPress(keyPress)
        }
    }

    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        let char = keyPress.characters.first
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

    /// Block forward nav on an unfinished drill — user must complete it first.
    private var canNavigateForward: Bool {
        if controller.isOnDrillStep && isEditorFocused {
            if case .drill(let exercise, _) = controller.currentStep {
                return progressStore.isExerciseCompleted(exercise.id)
            }
            return false
        }
        return !controller.isLastStep
    }

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

#Preview("Step canvas") {
    StepCanvasView(
        lesson: PreviewSamples.lesson,
        chapterTitle: PreviewSamples.chapter.title,
        progressStore: ProgressStore()
    )
    .frame(width: 900, height: 600)
}
