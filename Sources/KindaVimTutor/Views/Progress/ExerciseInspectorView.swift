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

            // Drill ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(.quaternary, lineWidth: 8)

                // Progress ring
                Circle()
                    .trim(from: 0, to: state.drillProgress)
                    .stroke(
                        state.isDrillComplete ? .green : .accentColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.4), value: state.drillProgress)

                // Center content
                VStack(spacing: 2) {
                    if state.isDrillComplete {
                        Image(systemName: "checkmark")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(.green)
                    } else {
                        Text("\(state.completedReps)")
                            .font(.system(size: 32, weight: .light, design: .monospaced))
                            .foregroundStyle(.primary)
                            .contentTransition(.numericText())
                        Text("of \(state.drillCount)")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .frame(width: 110, height: 110)

            // Metrics
            VStack(spacing: 14) {
                metricRow(
                    label: "Total Time",
                    value: String(format: "%.1fs", state.totalTime + state.elapsedTime),
                    best: state.bestTime.map { String(format: "%.1fs", $0) }
                )
                metricRow(
                    label: "Keystrokes",
                    value: "\(state.totalKeystrokes + state.keystrokeCount)",
                    best: state.bestKeystrokes.map { "\($0)" }
                )
                if state.completedReps > 0 {
                    metricRow(
                        label: "Avg / Rep",
                        value: String(format: "%.1fs", state.totalTime / Double(state.completedReps)),
                        best: nil
                    )
                }
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
                    state.onResetDrill?()
                } label: {
                    Label("Restart Drill", systemImage: "arrow.counterclockwise")
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
                .foregroundStyle(state.isDrillComplete ? .primary : .secondary)
                .contentTransition(.numericText())
            if let best {
                Text("best \(best)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.quaternary)
            }
        }
    }
}
