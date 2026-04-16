import SwiftUI

struct ContentStepView: View {
    let blocks: [ContentBlock]

    @State private var headingDone = false
    @State private var visibleBlockCount = 0

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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 56)
        .onDisappear {
            headingDone = false
            visibleBlockCount = 0
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
