import SwiftUI

/// Floating coaching panel for the Finder-navigation drill. Visual
/// language matches the tutor's left-rail `DrillSidebarSection`:
/// a progress ring showing reps-complete/total, Time + Keys metric
/// rows below, plus the bits specific to this exercise type:
/// a direction cue that tells the student which hjkl keys to press.
///
/// The panel shows while the drill is active. On completion the
/// panel is dismissed and the celebration happens back in the tutor
/// window (confetti + summary), so this view doesn't need a
/// completion state of its own.
struct FinderDrillCoachingView: View {
    let engine: FinderDrillEngine
    let modeMonitor: ModeMonitor

    private var showsWrongModeWarning: Bool {
        (engine.state == .active || engine.state == .seeding)
            && modeMonitor.currentMode == .insert
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            ring
                .frame(maxWidth: .infinity)
                .frame(height: 140)
            metrics
            Divider().opacity(0.4)
            if showsWrongModeWarning {
                wrongModeWarning
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                directionBlock
            }
        }
        .padding(18)
        .frame(width: 280)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.black.opacity(0.85))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 0.75)
        }
        .shadow(color: .black.opacity(0.35), radius: 14, y: 6)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "folder.fill")
                .font(.system(size: 10))
                .foregroundStyle(.orange)
            Text("Finder Navigation")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.7)
            Spacer()
        }
    }

    // MARK: - Ring

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: 8)
            Circle()
                .trim(from: 0, to: engine.drillProgress)
                .stroke(
                    engine.state == .drillCompleted ? .green : .accentColor,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.4), value: engine.drillProgress)

            if engine.state == .drillCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(.green)
            } else {
                VStack(spacing: 2) {
                    Text("\(engine.completedRepIndex)")
                        .font(.system(size: 44, weight: .light, design: .monospaced))
                        .contentTransition(.numericText())
                        .foregroundStyle(.primary)
                    Text("of \(engine.reps.count)")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(6)
    }

    // MARK: - Metrics

    private var metrics: some View {
        VStack(alignment: .leading, spacing: 6) {
            metricRow(
                label: "Time",
                value: String(format: "%.1fs", engine.totalTime + engine.elapsedTime)
            )
            metricRow(
                label: "Keys",
                value: "\(engine.totalMoves + engine.moveCount)"
            )
        }
    }

    private func metricRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.quaternary)
                .tracking(0.3)
            Text(value)
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
        }
    }

    // MARK: - Wrong-mode warning

    /// When the student is in Insert mode during an active drill,
    /// hjkl types letters into selection-rename instead of moving the
    /// cursor. Prompt them to Esc back to Normal before they lose
    /// trust in the feedback loop.
    private var wrongModeWarning: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.system(size: 14))
                Text("You're in INSERT mode")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }
            HStack(spacing: 8) {
                Text("Press")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                KeyCapView(label: "esc", size: .small)
                Text("to switch to NORMAL")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.orange.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.5), lineWidth: 1)
        )
    }

    // MARK: - Direction block

    /// Tells the student what they're trying to do in plain language:
    /// "Move to the red file" plus a row of hjkl keycaps showing
    /// which direction(s) to go. Keycaps highlight live when the
    /// student presses them (via the shared KeyPressTracker).
    @ViewBuilder
    private var directionBlock: some View {
        if let rep = engine.currentRep {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Circle().fill(.red).frame(width: 7, height: 7)
                    Text("Move to the red file")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                    Spacer()
                }
                directionHint
            }
            .id("rep-\(engine.completedRepIndex)-\(rep.target)")
            .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
    }

    private var directionHint: some View {
        let delta = engine.directionToTarget
        return HStack(spacing: 6) {
            // Left hint
            keyCap("h", show: (delta?.dx ?? 0) < 0,
                   count: max(-(delta?.dx ?? 0), 0))
            // Down hint
            keyCap("j", show: (delta?.dy ?? 0) > 0,
                   count: max(delta?.dy ?? 0, 0))
            // Up hint
            keyCap("k", show: (delta?.dy ?? 0) < 0,
                   count: max(-(delta?.dy ?? 0), 0))
            // Right hint
            keyCap("l", show: (delta?.dx ?? 0) > 0,
                   count: max(delta?.dx ?? 0, 0))
            Spacer()
        }
    }

    private func keyCap(_ key: String, show: Bool, count: Int) -> some View {
        HStack(spacing: 4) {
            KeyCapView(label: key, size: .regular)
                .opacity(show ? 1.0 : 0.22)
            if show && count > 1 {
                Text("×\(count)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
