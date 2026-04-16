import SwiftUI

struct ExerciseContainerView: View {
    let exercise: Exercise
    let exerciseNumber: Int
    let progressStore: ProgressStore
    @State private var engine = ExerciseEngine()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(alignment: .firstTextBaseline) {
                Text("Exercise \(exerciseNumber)")
                    .font(.headline)
                Spacer()
                if engine.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .imageScale(.large)
                        .transition(.scale.combined(with: .opacity))
                }
                difficultyBadge
            }

            // Instruction
            Text(exercise.instruction)
                .font(Typography.body)
                .lineSpacing(2)

            // Editor
            VStack(spacing: 0) {
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

                // Status bar
                HStack(spacing: 14) {
                    if case .completed(let time, let keystrokes) = engine.state {
                        Label(String(format: "%.1fs", time), systemImage: "clock")
                        Label("\(keystrokes) actions", systemImage: "keyboard")
                    } else if case .active = engine.state {
                        Label(String(format: "%.1fs", engine.elapsedTime), systemImage: "clock")
                        Label("\(engine.keystrokeCount) actions", systemImage: "keyboard")
                    }
                    Spacer()
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            engine.reset()
                        }
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                }
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.primary.opacity(0.03))
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(engine.isCompleted ? .green : .clear, lineWidth: 2)
            }
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

            // Hints
            if !exercise.hints.isEmpty {
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(exercise.hints, id: \.self) { hint in
                            Text(hint)
                                .font(Typography.bodySecondary)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 4)
                } label: {
                    Label("Hint", systemImage: "lightbulb")
                        .font(Typography.bodySecondary)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.primary.opacity(0.03))
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
        .animation(.spring(duration: 0.3), value: engine.isCompleted)
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
        return CGFloat(lineCount) * 22 + 28
    }

    private var difficultyBadge: some View {
        Text(exercise.difficulty.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.semibold)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule()
                    .fill(difficultyColor.opacity(0.12))
            }
            .foregroundStyle(difficultyColor)
    }

    private var difficultyColor: Color {
        switch exercise.difficulty {
        case .learn: .green
        case .practice: .blue
        case .master: .orange
        }
    }
}
