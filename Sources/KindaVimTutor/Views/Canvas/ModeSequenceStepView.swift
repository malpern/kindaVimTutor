import SwiftUI

/// Drill that validates against kindaVim's live mode rather than text.
/// Shows Normal + Insert as active targets the student must cycle through,
/// plus an optional muted Visual chip that jumps to a later lesson if
/// clicked (used to foreshadow Ch5 from the Ch1 modes lesson).
struct ModeSequenceStepView: View {
    let expected: [VimMode]
    let instruction: String
    let visualPreviewLessonId: String?
    let monitor: ModeMonitor
    var onComplete: (() -> Void)?
    var onJumpToLesson: ((String) -> Void)?

    @State private var progressIndex: Int = 0
    @State private var didComplete: Bool = false
    @State private var visualDiscovered: Bool = false

    private var currentExpected: VimMode? {
        progressIndex < expected.count ? expected[progressIndex] : nil
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 20)

            // Sequence targets — one chip per step, the active one glowing.
            HStack(spacing: 16) {
                ForEach(Array(expected.enumerated()), id: \.offset) { idx, mode in
                    SequenceTarget(
                        mode: mode,
                        state: state(for: idx)
                    )
                }
            }

            // Instruction line, follows the sequence.
            AnnotatedText(string: currentInstruction,
                          font: .system(size: 17, weight: .regular),
                          capSize: .small,
                          foregroundStyle: .secondary)
                .frame(maxWidth: 560)
                .multilineTextAlignment(.leading)

            // Visual preview chip (if this lesson wants to mention it).
            if let target = visualPreviewLessonId {
                VisualPreviewPill(
                    discovered: visualDiscovered,
                    onTap: { onJumpToLesson?(target) }
                )
                .padding(.top, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 48)
        .padding(.vertical, 24)
        .onChange(of: monitor.currentMode) { _, newMode in
            if newMode == .visual { visualDiscovered = true }

            guard !didComplete else { return }
            if newMode == currentExpected {
                progressIndex += 1
                if progressIndex >= expected.count {
                    didComplete = true
                    onComplete?()
                }
            }
        }
        .onAppear {
            if let first = expected.first, monitor.currentMode == first {
                progressIndex = 1
                if expected.count == 1 {
                    didComplete = true
                    onComplete?()
                }
            }
        }
        .accessibilityIdentifier("ModeSequenceStep")
    }

    private func state(for idx: Int) -> SequenceTarget.State {
        if idx < progressIndex { return .done }
        if idx == progressIndex { return .active }
        return .upcoming
    }

    private var currentInstruction: String {
        if didComplete {
            return "Nice — that's the rhythm. Press `]` to continue."
        }
        return instruction
    }
}

private struct SequenceTarget: View {
    let mode: VimMode
    let state: State

    enum State { case upcoming, active, done }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(state == .upcoming ? Color.secondary.opacity(0.35) : mode.color)
                .frame(width: 9, height: 9)
            Text(mode.displayName)
                .font(.system(.callout, design: .monospaced, weight: .bold))
                .foregroundStyle(state == .upcoming ? .secondary : .primary)
            if state == .done {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.green.opacity(0.85))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(background)
        }
        .overlay {
            Capsule()
                .strokeBorder(state == .active ? mode.color : Color.clear,
                              lineWidth: 1.5)
        }
        .scaleEffect(state == .active ? 1.05 : 1.0)
        .shadow(color: state == .active ? mode.color.opacity(0.35) : .clear,
                radius: 8, y: 1)
        .animation(.spring(duration: 0.25), value: state)
    }

    private var background: Color {
        switch state {
        case .upcoming: return Color.secondary.opacity(0.08)
        case .active:   return mode.color.opacity(0.18)
        case .done:     return mode.color.opacity(0.14)
        }
    }
}

private struct VisualPreviewPill: View {
    var discovered: Bool = false
    var onTap: () -> Void
    @State private var hover = false

    private var purple: Color { VimMode.visual.color }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Circle()
                    .fill(purple.opacity(dotOpacity))
                    .frame(width: 7, height: 7)
                Text("visual")
                    .font(.system(.caption, design: .monospaced, weight: .semibold))
                    .foregroundStyle(labelStyle)
                if discovered {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.green.opacity(0.85))
                        .transition(.scale.combined(with: .opacity))
                }
                Image(systemName: "arrow.up.forward")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.tertiary.opacity(hover ? 1.0 : 0.6))
                Text("Chapter 5")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.tertiary.opacity(hover ? 1.0 : 0.55))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(discovered
                          ? purple.opacity(hover ? 0.22 : 0.15)
                          : Color.secondary.opacity(hover ? 0.10 : 0.05))
            }
            .overlay {
                Capsule()
                    .strokeBorder(discovered
                                  ? purple.opacity(0.45)
                                  : Color.secondary.opacity(0.18),
                                  lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.25), value: discovered)
        .onHover { hovering in
            hover = hovering
            if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
        .help("Jump to Chapter 5 — Visual Mode")
    }

    private var dotOpacity: Double {
        if discovered { return 0.9 }
        return hover ? 0.6 : 0.35
    }

    private var labelStyle: Color {
        if discovered { return .primary }
        return .secondary.opacity(hover ? 1.0 : 0.75)
    }
}
