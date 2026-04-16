import SwiftUI

struct ExerciseContainerView: View {
    let exercise: Exercise
    let exerciseNumber: Int
    let progressStore: ProgressStore
    @State private var engine = ExerciseEngine()

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
                }
            )
            .frame(minHeight: editorHeight, maxHeight: editorHeight)
            .background(AppColors.editorBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            // Completion stats + reset — only shown when relevant
            HStack(spacing: 12) {
                if case .completed(let time, let keystrokes) = engine.state {
                    Text("\(String(format: "%.1f", time))s · \(keystrokes) keystrokes")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        engine.reset()
                    }
                } label: {
                    Text("Reset")
                        .font(.system(size: 12))
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.tertiary)
            }
            .padding(.top, 8)

            // Hints
            if !exercise.hints.isEmpty {
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(exercise.hints, id: \.self) { hint in
                            Text(hint)
                                .font(Typography.bodySecondary)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 4)
                } label: {
                    Label("Hint", systemImage: "lightbulb")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                }
                .padding(.top, 8)
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
        .animation(.easeInOut(duration: 0.2), value: engine.isCompleted)
        .onChange(of: engine.isCompleted) {
            if case .completed(let time, let keystrokes) = engine.state {
                let result = ExerciseResult(
                    exerciseId: exercise.id,
                    completedAt: Date(),
                    timeSeconds: time,
                    keystrokeCount: keystrokes,
                    attempts: 1,
                    hintsUsed: max(0, engine.currentHintIndex + 1)
                )
                progressStore.recordCompletion(result)
            }
        }
    }

    private var editorHeight: CGFloat {
        let lineCount = max(exercise.initialText.components(separatedBy: "\n").count, 1)
        return CGFloat(lineCount) * 20 + 32
    }
}
