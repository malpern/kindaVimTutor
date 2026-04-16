import SwiftUI

struct ExerciseContainerView: View {
    let exercise: Exercise
    let exerciseNumber: Int
    let progressStore: ProgressStore
    @State private var engine = ExerciseEngine()
    @State private var isEditorFocused = false
    @State private var isEditorHovered = false
    @State private var showHint = false

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

            // Editor with interactive states
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

            // Stats + actions
            HStack(spacing: 8) {
                if case .completed(let time, let keystrokes) = engine.state {
                    Text("\(String(format: "%.1f", time))s · \(keystrokes) keystrokes")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                if !exercise.hints.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            showHint.toggle()
                        }
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(showHint ? .secondary : .tertiary)
                    .help("Show hint")
                }
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showHint = false
                        engine.reset()
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12))
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.tertiary)
                .help("Reset exercise")
            }
            .padding(.top, 8)

            // Hint — shown inline below the stats when requested
            if !exercise.hints.isEmpty, showHint {
                Text(exercise.hints.first ?? "")
                    .font(Typography.bodySecondary)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                    .transition(.opacity)
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
        // Resting state — subtle but visible border
        return .primary.opacity(0.1)
    }

    private var editorBorderWidth: CGFloat {
        if isEditorFocused || engine.isCompleted {
            return 2
        }
        return 1
    }
}
