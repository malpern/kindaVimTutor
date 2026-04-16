import SwiftUI

struct ExerciseInspectorView: View {
    let state: ExerciseInspectorState

    var body: some View {
        VStack(spacing: 24) {
            // Header
            Text("Exercise \(state.exerciseNumber)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.8)

            // Ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(.quaternary, lineWidth: 6)

                // Progress ring — fills based on completion
                if state.isCompleted {
                    Circle()
                        .trim(from: 0, to: 1)
                        .stroke(.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }

                // Center content
                VStack(spacing: 2) {
                    if state.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.green)
                    } else {
                        Text(String(format: "%.1f", state.elapsedTime))
                            .font(.system(size: 28, weight: .light, design: .monospaced))
                            .foregroundStyle(.primary)
                            .contentTransition(.numericText())
                        Text("seconds")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .frame(width: 100, height: 100)
            .animation(.easeInOut(duration: 0.3), value: state.isCompleted)

            // Metrics
            VStack(spacing: 16) {
                metricRow(
                    label: "Time",
                    value: state.isCompleted
                        ? String(format: "%.1fs", state.completedTime)
                        : String(format: "%.1fs", state.elapsedTime),
                    best: state.bestTime.map { String(format: "%.1fs", $0) }
                )
                metricRow(
                    label: "Keystrokes",
                    value: "\(state.isCompleted ? state.completedKeystrokes : state.keystrokeCount)",
                    best: state.bestKeystrokes.map { "\($0)" }
                )
                metricRow(
                    label: "Attempt",
                    value: "\(state.attemptCount)",
                    best: nil
                )
            }

            Spacer()

            // Actions
            VStack(spacing: 8) {
                if !state.hints.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            state.showHint.toggle()
                        }
                    } label: {
                        Label(state.showHint ? "Hide Hint" : "Show Hint",
                              systemImage: "questionmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)

                    if state.showHint, let hint = state.hints.first {
                        Text(hint)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }
                }

                Button {
                    state.onReset?()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }
            .font(.system(size: 13))
        }
        .padding(20)
        .frame(width: 180)
    }

    private func metricRow(label: String, value: String, best: String?) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.quaternary)
                .textCase(.uppercase)
                .tracking(0.3)
            Text(value)
                .font(.system(size: 18, weight: .light, design: .monospaced))
                .foregroundStyle(state.isCompleted ? .primary : .secondary)
                .contentTransition(.numericText())
            if let best {
                Text("best \(best)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.quaternary)
            }
        }
    }
}
