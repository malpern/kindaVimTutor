import SwiftUI

/// Minimal floating coaching panel for the Finder-navigation drill.
/// Shows only what the student needs to act: the goal, which rep
/// they're on, and which key(s) to press. No visible timer or
/// keystroke counter — those are recorded for the completion screen
/// but kept off the live UI so the student isn't rushed.
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
            Divider().opacity(0.4)
            if showsWrongModeWarning {
                wrongModeWarning
                    .transition(.opacity)
            } else {
                directionBlock
                    .transition(.opacity)
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
        .animation(.easeInOut(duration: 0.18), value: showsWrongModeWarning)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.orange)
                Text("Exercise")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.7)
                Spacer()
                Text("\(min(engine.completedRepIndex + 1, engine.reps.count)) / \(engine.reps.count)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.tertiary)
            }
            Text(engine.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(engine.subtitle)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Wrong-mode warning

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
        }
    }

    private var directionHint: some View {
        let delta = engine.directionToTarget
        return HStack(spacing: 6) {
            keyCap("h", show: (delta?.dx ?? 0) < 0,
                   count: max(-(delta?.dx ?? 0), 0))
            keyCap("j", show: (delta?.dy ?? 0) > 0,
                   count: max(delta?.dy ?? 0, 0))
            keyCap("k", show: (delta?.dy ?? 0) < 0,
                   count: max(-(delta?.dy ?? 0), 0))
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
