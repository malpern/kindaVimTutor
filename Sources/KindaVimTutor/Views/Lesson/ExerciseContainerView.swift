import SwiftUI

struct ExerciseContainerView: View {
    let exercise: Exercise
    let exerciseNumber: Int
    let progressStore: ProgressStore
    let inspectorState: ExerciseInspectorState
    @State private var engine = ExerciseEngine()
    @State private var isEditorFocused = false
    @State private var isEditorHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Label
            HStack {
                if engine.isCompleted {
                    Text("Exercise \(exerciseNumber) ") + Text(Image(systemName: "checkmark"))
                } else {
                    Text("Exercise \(exerciseNumber)")
                }
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(engine.isCompleted ? .secondary : .tertiary)
            .textCase(.uppercase)
            .tracking(0.8)

            Spacer().frame(height: 12)

            // Instruction
            Text(exercise.instruction)
                .font(Typography.body)
                .lineSpacing(4)

            Spacer().frame(height: 12)

            // Editor
            ExerciseEditorView(
                initialText: exercise.initialText,
                initialCursorPosition: exercise.initialCursorPosition,
                onTextChange: { text, cursor in
                    engine.textDidChange(currentText: text, cursorPosition: cursor)
                },
                onSelectionChange: { text, cursor in
                    engine.selectionDidChange(currentText: text, cursorPosition: cursor)
                },
                onFocusChange: { focused in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isEditorFocused = focused
                    }
                    if focused {
                        inspectorState.show(
                            exerciseNumber: exerciseNumber,
                            exerciseId: exercise.id,
                            hints: exercise.hints
                        )
                        inspectorState.onReset = { [self] in
                            engine.reset()
                        }
                        updateInspector()
                    } else {
                        inspectorState.hide()
                    }
                }
            )
            .frame(minHeight: editorHeight, maxHeight: editorHeight)
            .background(AppColors.editorBackground, in: editorShape)
            .clipShape(editorShape)
            .overlay {
                editorShape
                    .strokeBorder(editorBorderColor, lineWidth: editorBorderWidth)
            }
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.12)) {
                    isEditorHovered = hovering
                }
            }
        }
        .onAppear {
            engine.start(exercise)
        }
        .onDisappear {
            engine.stop()
        }
        .onChange(of: exercise) {
            engine.start(exercise)
        }
        .onChange(of: engine.elapsedTime) {
            if isEditorFocused { updateInspector() }
        }
        .onChange(of: engine.keystrokeCount) {
            if isEditorFocused { updateInspector() }
        }
        .animation(.easeInOut(duration: 0.2), value: engine.isCompleted)
        .onChange(of: engine.isCompleted) {
            if isEditorFocused { updateInspector() }
            if case .completed(let time, let keystrokes) = engine.state {
                let result = ExerciseResult(
                    exerciseId: exercise.id,
                    completedAt: Date(),
                    timeSeconds: time,
                    keystrokeCount: keystrokes,
                    attempts: engine.attemptCount,
                    hintsUsed: 0
                )
                progressStore.recordCompletion(result)
            }
        }
    }

    private func updateInspector() {
        inspectorState.update(
            engine: engine,
            bestResult: progressStore.bestResult(for: exercise.id)
        )
    }

    // MARK: - Editor styling

    private var editorShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
    }

    private var editorHeight: CGFloat {
        let lineCount = max(exercise.initialText.components(separatedBy: "\n").count, 1)
        return CGFloat(lineCount) * 20 + 32
    }

    private var editorBorderColor: Color {
        if engine.isCompleted {
            return .green.opacity(0.5)
        }
        if isEditorFocused {
            return Color.accentColor.opacity(0.6)
        }
        if isEditorHovered {
            return .primary.opacity(0.2)
        }
        return .primary.opacity(0.1)
    }

    private var editorBorderWidth: CGFloat {
        if isEditorFocused || engine.isCompleted {
            return 2
        }
        return 1
    }
}
