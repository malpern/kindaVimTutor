import SwiftUI

struct ExplanationView: View {
    let blocks: [ContentBlock]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                contentBlockView(block)
            }
        }
    }

    @ViewBuilder
    private func contentBlockView(_ block: ContentBlock) -> some View {
        switch block {
        case .text(let text):
            Text(text)
                .font(Typography.body)
                .lineSpacing(4)

        case .heading(let text):
            Text(text)
                .font(Typography.sectionHeading)
                .tracking(Typography.titleTracking)
                .padding(.top, 16)

        case .tip(let text):
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: "lightbulb")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13))
                Text(text)
                    .font(Typography.bodySecondary)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.tipBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

        case .important(let text):
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13))
                Text(text)
                    .font(Typography.bodySecondary)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.importantBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

        case .keyCommand(let keys, let description):
            HStack(spacing: 12) {
                Text(keys.joined(separator: " "))
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .frame(minWidth: 50, alignment: .leading)
                Text(description)
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 3)

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
            .font(Typography.bodySecondary)
            .foregroundStyle(.secondary)

        case .spacer:
            Spacer().frame(height: 8)
        }
    }

    private func codeBlock(label: String, code: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.tertiary)
            Text(code)
                .font(Typography.code)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.codeBackground, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }
}
