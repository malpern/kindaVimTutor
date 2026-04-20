import SwiftUI

/// Minimal floating coaching panel for the Finder-navigation drill.
/// Flat layout, one vertical axis, but with deliberate pops of
/// color: orange for the exercise identity (Finder), accent blue
/// for the action the student should take next, red for the target.
struct FinderDrillCoachingView: View {
    let engine: FinderDrillEngine
    let modeMonitor: ModeMonitor

    /// Number of selection changes observed while the student was in
    /// Insert mode during the current rep. Each one is a clue that
    /// they tried to act without realizing they're in the wrong mode.
    /// At two, the "press esc" prompt escalates from a calm nudge to
    /// an orange warning.
    @State private var insertModeActivity: Int = 0

    private var showsInsertModePrompt: Bool {
        (engine.state == .active || engine.state == .seeding)
            && modeMonitor.currentMode == .insert
    }

    private var isInsertModeEscalated: Bool { insertModeActivity >= 2 }

    var body: some View {
        card
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(width: 300)
            .background(panelBackground)
            .overlay(panelBorder)
            .shadow(color: .black.opacity(0.35), radius: 14, y: 6)
            .fixedSize(horizontal: false, vertical: true)
            .animation(.easeInOut(duration: 0.18), value: showsInsertModePrompt)
            .onChange(of: engine.currentSelection) { _, _ in
                // Count selection activity that happens *while* the
                // student is in Insert mode — that's the signal that
                // they're trying to drive the drill without realizing
                // the mode is wrong.
                guard modeMonitor.currentMode == .insert,
                      engine.state == .active || engine.state == .seeding
                else { return }
                insertModeActivity += 1
            }
            .onChange(of: modeMonitor.currentMode) { _, newValue in
                // Any transition away from insert resets the count —
                // if they escape to normal, the next time they dip
                // into insert starts over with the calm tone.
                if newValue != .insert {
                    insertModeActivity = 0
                }
            }
            .onChange(of: engine.completedRepIndex) { _, _ in
                if engine.state == .active || engine.state == .seeding {
                    insertModeActivity = 0
                }
            }
    }

    @ViewBuilder
    private var card: some View {
        VStack(alignment: .leading, spacing: 16) {
            titleRow
            if engine.state == .repCompleted {
                successFlash.transition(.opacity)
            } else if showsInsertModePrompt {
                insertModeGuidance.transition(.opacity)
            } else {
                directionGuidance.transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: engine.state)
    }

    // MARK: - Success flash

    /// Shown briefly on rep completion, before the next rep begins.
    /// A soft green checkmark + "Got it" — enough to feel rewarded
    /// without breaking the rhythm of the drill.
    private var successFlash: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, value: engine.completedRepIndex)
            VStack(alignment: .leading, spacing: 2) {
                Text("Got it")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(engine.completedRepIndex >= engine.reps.count
                     ? "Drill complete"
                     : "Next rep starting…")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - Title row

    private var titleRow: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "folder.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color.orange)
                .frame(width: 22, height: 22)
                .background(
                    Circle().fill(Color.orange.opacity(0.15))
                )
            VStack(alignment: .leading, spacing: 1) {
                Text(engine.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("Exercise \(min(engine.completedRepIndex + 1, engine.reps.count)) / \(engine.reps.count)")
                    .font(.system(size: 10, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
                    .tracking(0.7)
            }
            Spacer()
        }
    }

    // MARK: - Direction guidance

    private var directionGuidance: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Circle().fill(.red).frame(width: 8, height: 8)
                Text(engine.currentRepInstruction)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .id("repInstruction-\(engine.completedRepIndex)")
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
            directionKeys
        }
        .animation(.easeOut(duration: 0.22), value: engine.completedRepIndex)
    }

    private var directionKeys: some View {
        let delta = engine.directionToTarget
        return HStack(spacing: 8) {
            directionKey("h", active: (delta?.dx ?? 0) < 0,
                         count: max(-(delta?.dx ?? 0), 0))
            directionKey("j", active: (delta?.dy ?? 0) > 0,
                         count: max(delta?.dy ?? 0, 0))
            directionKey("k", active: (delta?.dy ?? 0) < 0,
                         count: max(-(delta?.dy ?? 0), 0))
            directionKey("l", active: (delta?.dx ?? 0) > 0,
                         count: max(delta?.dx ?? 0, 0))
            Spacer()
        }
    }

    /// A keycap with an accent-colored halo when it's the next key
    /// the student should press. Inactive keys fade back so the
    /// active ones read as the primary instruction at a glance.
    private func directionKey(_ key: String, active: Bool, count: Int) -> some View {
        HStack(spacing: 4) {
            KeyCapView(label: key, size: .regular)
                .padding(active ? 3 : 0)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.accentColor.opacity(active ? 0.22 : 0))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.accentColor.opacity(active ? 0.55 : 0),
                                      lineWidth: 1)
                )
                .opacity(active ? 1.0 : 0.28)
            if active && count > 1 {
                Text("×\(count)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .animation(.easeOut(duration: 0.15), value: active)
    }

    // MARK: - Insert-mode guidance

    private var insertModeGuidance: some View {
        let tint: Color = isInsertModeEscalated ? .orange : .secondary
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Press")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                KeyCapView(label: "esc", size: .small)
                Text("to switch to NORMAL mode")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
            }
            Text(isInsertModeEscalated
                 ? "You're still in insert mode"
                 : "You're in insert mode")
                .font(.system(size: 11))
                .foregroundStyle(tint)
        }
        .animation(.easeInOut(duration: 0.22), value: isInsertModeEscalated)
    }

    // MARK: - Panel chrome

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(.black.opacity(0.88))
    }

    private var panelBorder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(.white.opacity(0.1), lineWidth: 0.75)
    }
}
