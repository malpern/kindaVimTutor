import SwiftUI

/// A lesson content slide. Renders a grouped run of `ContentBlock`s — one
/// heading plus a mix of text, tips, key commands, and code examples.
struct ContentStepView: View {
    let blocks: [ContentBlock]

    @State private var appeared = false

    var body: some View {
        VStack {
            Spacer()

            VStack(alignment: .leading, spacing: 20) {
                ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                    contentBlockView(block)
                }
            }
            .frame(maxWidth: 640, alignment: .leading)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 56)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.35), value: appeared)
        .onAppear { appeared = true }
        .onDisappear { appeared = false }
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
            calloutRow(icon: "lightbulb", text: text, background: AppColors.tipBackground)

        case .important(let text):
            calloutRow(icon: "exclamationmark.triangle", text: text, background: AppColors.importantBackground)

        case .keyCommand(let keys, let description):
            HStack(alignment: .top, spacing: 16) {
                Text(keys.joined(separator: " "))
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .frame(minWidth: 56, alignment: .leading)
                Text(description)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
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

    private func calloutRow(icon: String, text: String, background: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .font(.system(size: 14))
                .frame(width: 18, alignment: .topLeading)
                .padding(.top, 2)
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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

#Preview("Content slide") {
    ContentStepView(blocks: PreviewSamples.blocks)
        .frame(width: 900, height: 600)
}
