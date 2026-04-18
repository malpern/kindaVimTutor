import SwiftUI

/// Larger, always-visible kindaVim mode chip pinned to the detail view.
/// Mirrors the toolbar indicator but at a readable size, with a caption
/// when no mode has been broadcast yet so the learner knows what to do.
struct LiveModeBadge: View {
    @Environment(ModeMonitor.self) private var modeMonitor

    var body: some View {
        Group {
            if shouldRender {
                HStack(spacing: 8) {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 10, height: 10)
                    Text(label)
                        .font(.system(.caption, design: .monospaced, weight: .bold))
                        .foregroundStyle(labelColor)
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background {
                    Capsule()
                        .fill(backgroundColor)
                        .overlay(
                            Capsule().strokeBorder(borderColor, lineWidth: 1)
                        )
                }
                .shadow(color: .black.opacity(0.22), radius: 8, y: 2)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .accessibilityIdentifier("LiveModeBadge")
                .accessibilityLabel("kindaVim mode: \(label)")
            }
        }
        .animation(.spring(duration: 0.3), value: modeMonitor.currentMode)
        .animation(.spring(duration: 0.3), value: modeMonitor.isKindaVimRunning)
    }

    /// Render only when we have something meaningful to show — a known mode,
    /// or a warning that kindaVim isn't running. Hide the pre-mode placeholder.
    private var shouldRender: Bool {
        if !modeMonitor.isKindaVimRunning { return true }
        return modeMonitor.currentMode != .unknown
    }

    private var label: String {
        guard modeMonitor.isKindaVimRunning else { return "kindaVim off" }
        switch modeMonitor.currentMode {
        case .normal: return "NORMAL"
        case .insert: return "INSERT"
        case .visual: return "VISUAL"
        case .unknown: return ""
        }
    }

    private var dotColor: Color {
        guard modeMonitor.isKindaVimRunning else { return .orange }
        return modeMonitor.currentMode.color
    }

    private var labelColor: Color {
        guard modeMonitor.isKindaVimRunning else { return .secondary }
        return modeMonitor.currentMode == .unknown ? .secondary : .white
    }

    private var backgroundColor: Color {
        guard modeMonitor.isKindaVimRunning else { return .orange.opacity(0.08) }
        return modeMonitor.currentMode.color.opacity(0.14)
    }

    private var borderColor: Color {
        guard modeMonitor.isKindaVimRunning else { return .orange.opacity(0.3) }
        return modeMonitor.currentMode.color.opacity(0.3)
    }
}
