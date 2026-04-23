import SwiftUI

/// Toolbar wrapper that re-reads the monitor's state on every render,
/// which is what gives the Observation framework the hook it needs to
/// re-invalidate when `currentMode` flips. Reading the monitor's
/// properties inline inside `@ToolbarContentBuilder` doesn't reliably
/// establish that dependency.
struct ToolbarModeBadge: View {
    let monitor: ModeMonitor

    @State private var isHovering = false

    var body: some View {
        toolbarContent
            .opacity(isHovering ? 1 : 0.92)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .onHover { isHovering = $0 }
        .help(tooltip)
        .accessibilityLabel(tooltip)
    }

    @ViewBuilder
    private var toolbarContent: some View {
        if monitor.isKindaVimRunning {
            HStack(spacing: 5) {
                Circle()
                    .fill(monitor.currentMode.color)
                    .frame(width: 7, height: 7)
                Text(monitor.currentMode.displayName)
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                Capsule().fill(monitor.currentMode.color.opacity(0.15))
            }
            .contentTransition(.numericText())
            .animation(.spring(duration: 0.25), value: monitor.currentMode)
        } else {
            HStack(spacing: 5) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                Text("kindaVim not detected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                Capsule().fill(.orange.opacity(0.08))
            }
        }
    }

    private var tooltip: String {
        guard monitor.isKindaVimRunning else {
            return "kindaVim isn't running — click the menu-bar icon to launch it."
        }
        switch monitor.currentMode {
        case .normal:
            return "kindaVim is in Normal mode. Press i to switch to Insert."
        case .insert:
            return "kindaVim is in Insert mode. Press Esc to switch to Normal."
        case .visual:
            return "kindaVim is in Visual mode. Press Esc to return to Normal."
        case .unknown:
            return "Live kindaVim mode — green is Normal, blue is Insert, purple is Visual."
        }
    }
}

struct ModeIndicatorView: View {
    let mode: VimMode
    let isKindaVimRunning: Bool

    var body: some View {
        if isKindaVimRunning {
            modeLabel
        } else {
            notDetectedLabel
        }
    }

    private var modeLabel: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(mode.color)
                .frame(width: 7, height: 7)
            Text(mode.displayName)
                .font(.system(.caption, design: .monospaced, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background {
            Capsule()
                .fill(mode.color.opacity(0.15))
        }
        .contentTransition(.numericText())
        .animation(.spring(duration: 0.25), value: mode)
    }

    private var notDetectedLabel: some View {
        HStack(spacing: 5) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption2)
                .foregroundStyle(.orange)
            Text("kindaVim not detected")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background {
            Capsule()
                .fill(.orange.opacity(0.08))
        }
    }
}
