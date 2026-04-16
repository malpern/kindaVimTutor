import SwiftUI

struct ExplanationView: View {
    let blocks: [ContentBlock]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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

        case .heading(let text):
            Text(text)
                .font(Typography.heading)
                .padding(.top, 4)

        case .tip(let text):
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                    .font(.body)
                Text(text)
                    .font(Typography.body)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.tipBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

        case .important(let text):
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.body)
                Text(text)
                    .font(Typography.body)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.importantBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

        case .keyCommand(let keys, let description):
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    ForEach(keys, id: \.self) { key in
                        KeyCapView(label: key)
                    }
                }
                .frame(minWidth: 60)
                Text(description)
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 4)

        case .codeExample(let before, let after, let motion):
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Text("Using")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    KeyCapView(label: motion)
                }
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Before")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(before)
                            .font(Typography.code)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.codeBackground, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.tertiary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("After")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(after)
                            .font(Typography.code)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.codeBackground, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }
            }
            .padding(12)
            .background(AppColors.codeBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

        case .spacer:
            Spacer()
                .frame(height: 4)
        }
    }
}
