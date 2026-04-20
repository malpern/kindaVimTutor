import SwiftUI

/// Minimal floating coaching panel for the Finder-navigation drill.
/// Flat layout, one vertical axis, but with deliberate pops of
/// color: orange for the exercise identity (Finder), accent blue
/// for the action the student should take next, red for the target.
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
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
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
        VStack(alignment: .leading, spacing: 16) {
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
                Text("Exercise")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
                    .tracking(0.7)
            }
            Spacer()
            repDots
        }
    }

    /// Compact rep progress as filled/empty dots. Conveys "where am
    /// I in the drill" at a glance without requiring the student to
    /// read numbers.
    private var repDots: some View {
        HStack(spacing: 4) {
            ForEach(0..<engine.reps.count, id: \.self) { i in
                Circle()
                    .fill(i < engine.completedRepIndex
                          ? Color.accentColor
                          : (i == engine.completedRepIndex
                             ? Color.accentColor.opacity(0.45)
                             : Color.white.opacity(0.12)))
                    .frame(width: 6, height: 6)
            }
        }
    }

    // MARK: - Direction guidance

    private var directionGuidance: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Circle().fill(.red).frame(width: 8, height: 8)
                Text("Move to the red file")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
            }
            directionKeys
        }
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
