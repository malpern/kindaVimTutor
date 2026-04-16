import SwiftUI

struct ExerciseContainerView: View {
    let exercise: Exercise
    let exerciseNumber: Int
    let progressStore: ProgressStore
    @State private var engine = ExerciseEngine()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise header
            HStack {
                Label("Exercise \(exerciseNumber)", systemImage: "pencil.and.outline")
                    .font(.headline)
                Spacer()
                if engine.isCompleted {
                    Label("Done", systemImage: "checkmark.circle.fill")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))
                }
                difficultyBadge
            }

            // Instruction
            Text(exercise.instruction)
                .font(Typography.body)
                .foregroundStyle(.primary)

            // Live editor
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
                HStack(spacing: 16) {
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
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.quaternary.opacity(0.3))
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(editorBorderColor, lineWidth: 2)
            )
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(editorBorderColor)
                    .frame(width: 3)
                    .padding(.vertical, 1)
            }

            // Hints
            if !exercise.hints.isEmpty {
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(exercise.hints, id: \.self) { hint in
                            Text(hint)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                } label: {
                    Text("Hint")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .primary.opacity(0.06), radius: 8, x: 0, y: 2)
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
        return CGFloat(lineCount) * 20 + 24
    }

    private var editorBorderColor: Color {
        if engine.isCompleted {
            return .green
        }
        return AppColors.exerciseBorder.opacity(0.3)
    }

    private var difficultyBadge: some View {
        Text(exercise.difficulty.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background {
                Capsule()
                    .fill(difficultyColor.opacity(0.15))
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
