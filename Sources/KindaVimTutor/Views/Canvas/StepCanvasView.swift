import SwiftUI
import AppKit

struct StepCanvasView: View {
    let lesson: Lesson
    let chapterTitle: String
    let progressStore: ProgressStore
    let inspectorState: ExerciseInspectorState
    let modeMonitor: ModeMonitor
    var onNextLesson: (() -> Void)?
    var onJumpToLesson: ((String) -> Void)?

    @State private var controller = LessonStepController()
    @State private var isEditorFocused = false
    @State private var keyMonitor: Any?
    @State private var contentReady = false
    @State private var modeStepComplete = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                if let step = controller.currentStep {
                    Group {
                        switch step {
                        case .title(let lesson, let chapterTitle):
                            TitleStepView(lesson: lesson, chapterTitle: chapterTitle,
                                          onAdvance: { advanceForward() })

                        case .content(_, let blocks):
                            ContentStepView(
                                blocks: blocks,
                                onAutoAdvance: advanceForward,
                                onContentReady: {
                                    withAnimation(.easeIn(duration: 0.35)) {
                                        contentReady = true
                                    }
                                }
                            )

                        case .drill(let exercise, let exerciseNumber):
                            DrillStepView(
                                exercise: exercise,
                                exerciseNumber: exerciseNumber,
                                progressStore: progressStore,
                                inspectorState: inspectorState,
                                isEditorFocused: $isEditorFocused
                            )

                        case .modeSequence(_, let interactive):
                            if case .modeSequence(let expected, let instruction, let previewId) = interactive {
                                ModeSequenceStepView(
                                    expected: expected,
                                    instruction: instruction,
                                    visualPreviewLessonId: previewId,
                                    monitor: modeMonitor,
                                    onComplete: {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            modeStepComplete = true
                                        }
                                    },
                                    onJumpToLesson: { id in onJumpToLesson?(id) }
                                )
                            }
                        }
                    }
                    .id(step.id)
                    .transition(stepTransition)
                }

            }
            .frame(maxWidth: .infinity)
            .layoutPriority(1)  // step content flexes; chrome stays fixed

            // Canvas-level chrome — real sibling in the VStack, renders reliably.
            VStack(spacing: 16) {
                if shouldShowCanvasAdvanceHint {
                    AdvanceHintView("press to continue",
                                    action: canNavigateForward ? { advanceForward() } : nil)
                        .transition(.opacity.combined(with: .offset(y: 4)))
                }
                StepIndicatorView(
                    stepCount: controller.stepCount,
                    currentIndex: controller.currentStepIndex
                )
            }
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .accessibilityIdentifier("StepCanvas")
        .accessibilityLabel(accessibilityStatus)
        .onAppear {
            controller.loadLesson(lesson, chapterTitle: chapterTitle)
            AppCommandChannel.shared.registerController(controller)
            installKeyMonitor()
        }
        .onChange(of: lesson) {
            controller.loadLesson(lesson, chapterTitle: chapterTitle)
            isEditorFocused = false
            AppCommandChannel.shared.registerController(controller)
        }
        .onChange(of: controller.currentStepIndex) {
            AppCommandChannel.shared.notifyStateChanged()
            contentReady = false
            modeStepComplete = false
        }
        .onDisappear {
            AppCommandChannel.shared.registerController(nil)
            removeKeyMonitor()
        }
    }

    // MARK: - Key handling (window-level monitor)

    /// Install a local NSEvent monitor so `]` / `[` / space advance pages
    /// regardless of which view happens to hold SwiftUI focus. Without this,
    /// macOS can park focus on the toolbar's sidebar toggle after a step
    /// transition and our `.onKeyPress` never fires.
    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard let ch = event.charactersIgnoringModifiers?.first else { return event }
            // Don't hijack when modifier keys are pressed (Cmd+], etc.).
            if event.modifierFlags.contains(.command) || event.modifierFlags.contains(.option) {
                return event
            }
            // When the editor is focused for an active drill, let keys flow to
            // kindaVim — unless the drill is complete (then we let the page
            // advance even from the editor).
            let editorOwnsKey = isEditorFocused && controller.isOnDrillStep
            switch ch {
            case "]", " ":
                if editorOwnsKey && !canNavigateForward { return event }
                if canNavigateForward {
                    Task { @MainActor in advanceForward() }
                    return nil
                }
            case "[":
                if editorOwnsKey { return event }
                if canNavigateBackward {
                    Task { @MainActor in controller.previousStep() }
                    return nil
                }
            default:
                break
            }
            return event
        }
    }

    private func removeKeyMonitor() {
        if let m = keyMonitor {
            NSEvent.removeMonitor(m)
            keyMonitor = nil
        }
    }

    /// Whether to render the canvas-level "press to continue" CTA. Title steps
    /// have their own animated hint; content steps show it only once the
    /// heading and body blocks have finished animating in; drill steps show
    /// it only after the exercise is complete.
    private var shouldShowCanvasAdvanceHint: Bool {
        guard let step = controller.currentStep else { return false }
        switch step {
        case .title:
            return false
        case .content:
            return contentReady
        case .drill:
            return inspectorState.isDrillComplete
        case .modeSequence:
            return modeStepComplete
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
        case .modeSequence(let id, _):
            stepKind = "modeseq"; stepId = id
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
