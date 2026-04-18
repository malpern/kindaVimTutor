import SwiftUI

struct ContentStepView: View {
    let blocks: [ContentBlock]
    var onAutoAdvance: (() -> Void)?

    @State private var headingDone = false
    @State private var visibleBlockCount = 0
    @State private var autoAdvanceTask: Task<Void, Never>?
    @State private var dwellProgress: Double = 0

    // Separate heading from body blocks
    private var headingText: String? {
        if case .heading(let text) = blocks.first { return text }
        return nil
    }

    private var bodyBlocks: [ContentBlock] {
        if headingText != nil { return Array(blocks.dropFirst()) }
        return blocks
    }

    var body: some View {
        VStack {
            Spacer()

            VStack(alignment: .leading, spacing: 20) {
                // Heading types in
                if let heading = headingText {
                    TypewriterText(
                        heading,
                        font: .system(size: 28, weight: .bold),
                        foregroundStyle: .primary
                    ) {
                        headingDone = true
                        revealBodyBlocks()
                    }
                    .tracking(-0.6)
                } else {
                    // No heading — start revealing blocks immediately
                    EmptyView()
                        .onAppear { revealBodyBlocks() }
                }

                // Body blocks fade in sequentially
                ForEach(Array(bodyBlocks.enumerated()), id: \.offset) { index, block in
                    if index < visibleBlockCount {
                        contentBlockView(block)
                            .transition(.opacity.combined(with: .offset(y: 4)))
                    }
                }
            }
            .frame(maxWidth: 640, alignment: .leading)

            Spacer()

            advanceHint
                .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 56)
        .onAppear {
            scheduleAutoAdvance()
        }
        .onDisappear {
            autoAdvanceTask?.cancel()
            autoAdvanceTask = nil
            headingDone = false
            visibleBlockCount = 0
            dwellProgress = 0
        }
    }

    private var advanceHint: some View {
        HStack(spacing: 12) {
            Text("Next")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary.opacity(0.92))
            KeyCapView(label: "]", size: .regular)
            Text("or wait")
                .font(.system(size: 12))
                .foregroundStyle(.secondary.opacity(0.7))
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 2)
                Circle()
                    .trim(from: 0, to: dwellProgress)
                    .stroke(Color.accentColor.opacity(0.8), style: .init(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 16, height: 16)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(Color.primary.opacity(0.05))
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .opacity(shouldShowHint ? 1 : 0)
        .animation(.easeIn(duration: 0.3), value: shouldShowHint)
    }

    private var shouldShowHint: Bool {
        if headingDone { return true }
        if case .heading = blocks.first { return false }
        return true
    }

    private var autoAdvanceSeconds: Double {
        let words = blocks.reduce(0) { sum, block -> Int in
            switch block {
            case .text(let t), .heading(let t), .tip(let t), .important(let t):
                return sum + t.split(separator: " ").count
            case .keyCommand(_, let d):
                return sum + d.split(separator: " ").count
            default:
                return sum
            }
        }
        // ~2 words per second reading + 2.5s buffer, clamped to [5, 18].
        return max(5.0, min(18.0, Double(words) / 2.0 + 2.5))
    }

    private func scheduleAutoAdvance() {
        autoAdvanceTask?.cancel()
        let total = autoAdvanceSeconds
        autoAdvanceTask = Task { @MainActor in
            withAnimation(.linear(duration: total)) {
                dwellProgress = 1
            }
            try? await Task.sleep(for: .seconds(total))
            guard !Task.isCancelled else { return }
            onAutoAdvance?()
        }
    }

    private func revealBodyBlocks() {
        for i in 0..<bodyBlocks.count {
            withAnimation(.spring(duration: 0.4, bounce: 0.0).delay(Double(i) * 0.08)) {
                visibleBlockCount = i + 1
            }
        }
    }

    @ViewBuilder
    private func contentBlockView(_ block: ContentBlock) -> some View {
        switch block {
        case .heading(let text):
            Text(text)
                .font(.system(size: 28, weight: .bold))
                .tracking(-0.6)
                .fixedSize(horizontal: false, vertical: true)

        case .text(let text):
            Text(text)
                .font(.system(size: 16, weight: .regular))
                .lineSpacing(6)
                .foregroundStyle(.primary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)

        case .tip(let text):
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lightbulb")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 14))
                    .frame(width: 18, alignment: .topLeading)
                    .padding(.top, 2)
                Text(text)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.tipBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

        case .important(let text):
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 14))
                    .frame(width: 18, alignment: .topLeading)
                    .padding(.top, 2)
                Text(text)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.importantBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

        case .keyCommand(let keys, let description):
            HStack(alignment: .top, spacing: 16) {
                Text(keys.joined(separator: " "))
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .frame(minWidth: 56, alignment: .leading)
                Text(description)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)

        case .modePreview(let mode, let caption):
            HStack(spacing: 14) {
                ModeIndicatorView(mode: mode, isKindaVimRunning: true)
                Text(caption)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)

        case .codeExample(let before, let after, let motion):
            VStack(alignment: .leading, spacing: 10) {
                Text("Using  ") + Text(motion).font(.system(.body, design: .monospaced)).fontWeight(.medium)
                HStack(spacing: 20) {
                    codeBlock(label: "Before", code: before)
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.quaternary)
                    codeBlock(label: "After", code: after)
                }
            }
            .font(.system(size: 15))
            .foregroundStyle(.secondary)

        case .spacer:
            EmptyView()
        }
    }

    private func codeBlock(label: String, code: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.tertiary)
            Text(code)
                .font(.system(size: 14, design: .monospaced))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .background(AppColors.codeBackground, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }
}
