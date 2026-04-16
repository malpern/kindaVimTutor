import SwiftUI

struct DrillStepView: View {
    let exercise: Exercise
    let exerciseNumber: Int
    let progressStore: ProgressStore
    let inspectorState: ExerciseInspectorState
    @Binding var isEditorFocused: Bool
    @State private var engine = ExerciseEngine()
    @State private var isEditorHovered = false

    var isDrillComplete: Bool { engine.isDrillComplete }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 16) {
                // Exercise label with drill progress
                HStack(spacing: 6) {
                    if engine.isDrillComplete {
                        Text("Exercise \(exerciseNumber) ") + Text(Image(systemName: "checkmark"))
                    } else {
                        Text("Exercise \(exerciseNumber)")
                    }
                    if engine.completedReps > 0, !engine.isDrillComplete {
                        Text("— \(engine.completedReps)/\(engine.drillCount)")
                            .foregroundStyle(.quaternary)
                    }
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(engine.isDrillComplete ? .secondary : .tertiary)
                .textCase(.uppercase)
                .tracking(0.8)

                // Instruction
                Text(exercise.instruction)
                    .font(.system(size: 18, weight: .regular))
                    .lineSpacing(4)

                // Editor
                if let variation = engine.currentVariation {
                    ExerciseEditorView(
                        initialText: variation.initialText,
                        initialCursorPosition: variation.initialCursorPosition,
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
                                inspectorState.onResetRep = { engine.resetRep() }
                                inspectorState.onResetDrill = { engine.resetDrill() }
                                updateInspector()
                            } else {
                                inspectorState.hide()
                            }
                        }
                    )
                    .id(variation.initialText + "\(variation.initialCursorPosition)")
                    .frame(minHeight: editorHeight(for: variation), maxHeight: editorHeight(for: variation))
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
            }
            .frame(maxWidth: 520)

            Spacer()

            if engine.isDrillComplete {
                Text("Press l to continue")
                    .font(.system(size: 13))
                    .foregroundStyle(.quaternary)
                    .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 56)
        .onAppear {
            engine.start(exercise)
        }
        .onDisappear {
            engine.stop()
            inspectorState.hide()
        }
        .onChange(of: engine.elapsedTime) { updateInspector() }
        .onChange(of: engine.keystrokeCount) { updateInspector() }
        .onChange(of: engine.completedReps) { updateInspector() }
        .onChange(of: engine.isDrillComplete) {
            updateInspector()
            if engine.isDrillComplete {
                let result = ExerciseResult(
                    exerciseId: exercise.id,
                    completedAt: Date(),
                    timeSeconds: engine.totalTime,
                    keystrokeCount: engine.totalKeystrokes,
                    attempts: engine.drillCount,
                    hintsUsed: 0
                )
                progressStore.recordCompletion(result)
                if let session = engine.currentSession {
                    progressStore.saveDrillSession(session)
                }
            }
        }
    }

    private func updateInspector() {
        inspectorState.update(
            engine: engine,
            bestResult: progressStore.bestResult(for: exercise.id)
        )
    }

    private var editorShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
    }

    private func editorHeight(for variation: Exercise.Variation) -> CGFloat {
        let lineCount = max(variation.initialText.components(separatedBy: "\n").count, 1)
        return CGFloat(lineCount) * 20 + 32
    }

    private var editorBorderColor: Color {
        if engine.isDrillComplete { return .green.opacity(0.5) }
        if engine.isRepCompleted { return .green.opacity(0.3) }
        if isEditorFocused { return Color.accentColor.opacity(0.6) }
        if isEditorHovered { return .primary.opacity(0.2) }
        return .primary.opacity(0.1)
    }

    private var editorBorderWidth: CGFloat {
        (isEditorFocused || engine.isDrillComplete || engine.isRepCompleted) ? 2 : 1
    }
}
