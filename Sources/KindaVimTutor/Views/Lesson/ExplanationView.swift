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
                .foregroundStyle(.primary)
                .lineSpacing(3)

        case .heading(let text):
            Text(text)
                .font(Typography.sectionHeading)
                .tracking(Typography.titleTracking)
                .padding(.top, 12)

        case .tip(let text):
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                    .font(.callout)
                Text(text)
                    .font(Typography.bodySecondary)
                    .lineSpacing(2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.tipBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(AppColors.tipBorder, lineWidth: 1)
            }

        case .important(let text):
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.callout)
                Text(text)
                    .font(Typography.bodySecondary)
                    .lineSpacing(2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.importantBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(AppColors.importantBorder, lineWidth: 1)
            }

        case .keyCommand(let keys, let description):
            HStack(spacing: 14) {
                HStack(spacing: 4) {
                    ForEach(keys, id: \.self) { key in
                        KeyCapView(label: key, size: .large)
                    }
                }
                .frame(minWidth: 70, alignment: .leading)
                Text(description)
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)

        case .codeExample(let before, let after, let motion):
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text("Using")
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                    KeyCapView(label: motion)
                }
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Before")
                            .font(Typography.caption)
                            .foregroundStyle(.tertiary)
                            .textCase(.uppercase)
                        Text(before)
                            .font(Typography.code)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.codeBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.quaternary)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("After")
                            .font(Typography.caption)
                            .foregroundStyle(.tertiary)
                            .textCase(.uppercase)
                        Text(after)
                            .font(Typography.code)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.codeBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
            .padding(14)
            .background(AppColors.codeBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

        case .spacer:
            Spacer()
                .frame(height: 6)
        }
    }
}
