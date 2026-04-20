import SwiftUI

/// Minimal floating coaching panel for the Finder-navigation drill.
/// Intentionally flat — one card, one vertical axis. Three lines:
/// title + rep counter, one-line direction/guidance, small context
/// hint. No boxed sub-panels, no chrome, no live timer, no
/// keystroke counter.
struct FinderDrillCoachingView: View {
    let engine: FinderDrillEngine
    let modeMonitor: ModeMonitor

    @State private var insertModeEntries: Int = 0

    private var showsInsertModePrompt: Bool {
        (engine.state == .active || engine.state == .seeding)
            && modeMonitor.currentMode == .insert
    }

    private var isInsertModeEscalated: Bool { insertModeEntries >= 2 }

    var body: some View {
        card
            .padding(18)
            .frame(width: 300)
            .background(panelBackground)
            .overlay(panelBorder)
            .shadow(color: .black.opacity(0.35), radius: 14, y: 6)
            .fixedSize(horizontal: false, vertical: true)
            .animation(.easeInOut(duration: 0.18), value: showsInsertModePrompt)
            .onChange(of: modeMonitor.currentMode) { _, newValue in
                guard newValue == .insert,
                      engine.state == .active || engine.state == .seeding
                else { return }
                insertModeEntries += 1
            }
            .onChange(of: engine.completedRepIndex) { _, _ in
                if engine.state == .active || engine.state == .seeding {
                    insertModeEntries = 0
                }
            }
    }

    @ViewBuilder
    private var card: some View {
        VStack(alignment: .leading, spacing: 14) {
            titleRow
            if showsInsertModePrompt {
                insertModeGuidance.transition(.opacity)
            } else {
                directionGuidance.transition(.opacity)
            }
        }
    }

    // MARK: - Title row

    private var titleRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(engine.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
            Spacer()
            Text("\(min(engine.completedRepIndex + 1, engine.reps.count)) of \(engine.reps.count)")
                .font(.system(size: 11, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Active guidance

    private var directionGuidance: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle().fill(.red).frame(width: 7, height: 7)
                Text("Move to the red file")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            directionKeys
        }
    }

    private var directionKeys: some View {
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

    // MARK: - Insert-mode guidance

    /// Primary CTA + supporting context. Flat — no nested background
    /// card. Tone shifts from calm (tertiary accent) to warning
    /// (orange) after the student has fallen back into insert twice
    /// in the same rep.
    private var insertModeGuidance: some View {
        let tint: Color = isInsertModeEscalated ? .orange : .secondary
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("Press")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                KeyCapView(label: "esc", size: .small)
                Text("to switch to NORMAL mode")
                    .font(.system(size: 14))
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
            .fill(.black.opacity(0.85))
    }

    private var panelBorder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(.white.opacity(0.1), lineWidth: 0.75)
    }
}
