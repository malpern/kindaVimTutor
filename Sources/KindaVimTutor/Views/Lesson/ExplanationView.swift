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
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lightbulb")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13))
                    .frame(width: 18, alignment: .topLeading)
                    .padding(.top, 2)
                Text(text)
                    .font(Typography.bodySecondary)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.tipBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

        case .important(let text):
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13))
                    .frame(width: 18, alignment: .topLeading)
                    .padding(.top, 2)
                Text(text)
                    .font(Typography.bodySecondary)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.importantBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

        case .keyCommand(let keys, let description):
            HStack(alignment: .center, spacing: 12) {
                HStack(spacing: 6) {
                    ForEach(Array(keys.enumerated()), id: \.offset) { _, key in
                        KeyCapView(label: key, size: .small)
                    }
                }
                .frame(minWidth: 72, alignment: .leading)
                Text(description)
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 3)

        case .kindaVimInstallStatus:
            KindaVimInstallStatusBlock()

        case .modeFlowNarrative:
            ModeFlowNarrativeView()

        case .modesDemo:
            ModesDemoView()

        case .modeIndicatorSpotlight:
            ModeIndicatorSpotlightView()
                .frame(minHeight: 260)

        case .linkTip(_, _, let label, let url):
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lightbulb")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 14))
                    .frame(width: 18, alignment: .topLeading)
                    .padding(.top, 2)
                if let dest = URL(string: url) {
                    Link(destination: dest) {
                        HStack(spacing: 6) {
                            Text(label)
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.tipBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

        case .image(let name, let size):
            bundleImage(named: name)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: size, height: size)
                .padding(.vertical, 6)

        case .modePreview(let mode, let caption):
            HStack(spacing: 14) {
                ModeIndicatorView(mode: mode, isKindaVimRunning: true)
                Text(caption)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
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

    private func bundleImage(named name: String) -> Image {
        if let url = Bundle.module.url(forResource: name, withExtension: "png"),
           let ns = NSImage(contentsOf: url) {
            return Image(nsImage: ns)
        }
        return Image(systemName: "photo")
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
