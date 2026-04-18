import SwiftUI

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
