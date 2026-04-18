import SwiftUI

/// Compact drill progress block rendered at the top of the sidebar when
/// an exercise is active. Replaces the separate right-hand inspector panel.
struct DrillSidebarSection: View {
    let state: ExerciseInspectorState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Exercise \(state.exerciseNumber)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.7)

            ring
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)

            VStack(alignment: .leading, spacing: 6) {
                metricRow(
                    label: "Time",
                    value: String(format: "%.1fs", state.totalTime + state.elapsedTime),
                    best: state.bestTime.map { String(format: "%.1fs", $0) }
                )
                metricRow(
                    label: "Keys",
                    value: "\(state.totalKeystrokes + state.keystrokeCount)",
                    best: state.bestKeystrokes.map { "\($0)" }
                )
            }

            actions
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: 8)
            Circle()
                .trim(from: 0, to: state.drillProgress)
                .stroke(
                    state.isDrillComplete ? .green : .accentColor,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.4), value: state.drillProgress)

            if state.isDrillComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(.green)
            } else {
                VStack(spacing: 2) {
                    Text("\(state.completedReps)")
                        .font(.system(size: 44, weight: .light, design: .monospaced))
                        .contentTransition(.numericText())
                    Text("of \(state.drillCount)")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(6)
    }

    private func metricRow(label: String, value: String, best: String?) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.quaternary)
                .tracking(0.3)
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(value)
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundStyle(state.isDrillComplete ? .primary : .secondary)
                    .contentTransition(.numericText())
                if let best {
                    Text("· \(best)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.quaternary)
                }
            }
        }
    }

    @ViewBuilder
    private var actions: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !state.hints.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        state.showHint.toggle()
                    }
                } label: {
                    Label(state.showHint ? "Hide Hint" : "Show Hint",
                          systemImage: "questionmark.circle")
                }
                .buttonStyle(.borderless)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

                if state.showHint, let hint = state.hints.first {
                    Text(hint)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)
                        .transition(.opacity)
                }
            }

            Button {
                state.onResetDrill?()
            } label: {
                Label("Restart Drill", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.borderless)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
    }
}
