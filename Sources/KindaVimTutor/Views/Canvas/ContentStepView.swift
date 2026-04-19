import SwiftUI

struct ContentStepView: View {
    let blocks: [ContentBlock]
    var onAutoAdvance: (() -> Void)?
    /// Called once the heading has finished typing and all body blocks have
    /// faded in. The canvas uses this to time the appearance of its shared
    /// "press to continue" CTA — we only show the chip once reading material
    /// has settled.
    var onContentReady: (() -> Void)?

    @State private var headingDone = false
    @State private var visibleBlockCount = 0
    @State private var didNotifyReady = false

    private var headingText: String? {
        if case .heading(let text) = blocks.first { return text }
        return nil
    }

    private var bodyBlocks: [ContentBlock] {
        if headingText != nil { return Array(blocks.dropFirst()) }
        return blocks
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)

            VStack(alignment: .leading, spacing: 20) {
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
                    EmptyView()
                        .onAppear { revealBodyBlocks() }
                }

                ForEach(Array(bodyBlocks.enumerated()), id: \.offset) { index, block in
                    if index < visibleBlockCount {
                        contentBlockView(block)
                            .transition(.opacity.combined(with: .offset(y: 4)))
                    }
                }
            }
            .frame(maxWidth: 640, alignment: .leading)
            .animation(.spring(duration: 0.4, bounce: 0.0), value: visibleBlockCount)

            Spacer(minLength: 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 56)
        .onDisappear {
            headingDone = false
            visibleBlockCount = 0
        }
    }

    /// Renders a link inside the same visual shell as `.tip` — lightbulb
    /// icon, secondary text, same padding and background — so it reads as a
    /// supplementary resource rather than an alternative CTA.
    @ViewBuilder
    private func linkTipView(symbol: String, accent: LinkAccent, label: String, url: String) -> some View {
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
                            .lineSpacing(4)
                            .multilineTextAlignment(.leading)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            } else {
                Text(label)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.tipBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    /// Loads a loose PNG from the SwiftPM resource bundle. SwiftUI's
    /// `Image(_:bundle:)` only looks in asset catalogs, so raw PNGs
    /// need the NSImage(contentsOf:) path.
    private func bundleImage(named name: String) -> Image {
        if let url = Bundle.module.url(forResource: name, withExtension: "png"),
           let ns = NSImage(contentsOf: url) {
            return Image(nsImage: ns)
        }
        return Image(systemName: "photo")
    }

    private func revealBodyBlocks() {
        // Scope the animation to a single transaction driven by an
        // animation() modifier on the child, so layout animation cannot
        // cascade to sibling views outside the ContentStepView.
        for i in 0..<bodyBlocks.count {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(Double(i) * 0.08))
                visibleBlockCount = i + 1
            }
        }

        // Fire onContentReady after the last block has had a moment to settle.
        // 0.4s animation + (count-1)*0.08s stagger + small buffer.
        let settleDelay = 0.4 + Double(max(bodyBlocks.count - 1, 0)) * 0.08 + 0.15
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(settleDelay))
            guard !didNotifyReady else { return }
            didNotifyReady = true
            onContentReady?()
        }
    }

    @ViewBuilder
    private func contentBlockView(_ block: ContentBlock) -> some View {
        switch block {
        case .heading(let text):
            Text(text)
                .font(.system(size: 28, weight: .bold))
                .tracking(-0.6)

        case .text(let text):
            Text(text)
                .font(.system(size: 16, weight: .regular))
                .lineSpacing(6)
                .foregroundStyle(.primary.opacity(0.85))

        case .tip(let text):
            // Inline SF-Symbol + text concatenation so wrapping works natively.
            // Wrapping Text in .padding(16)+.background() currently breaks the
            // wrap (SwiftUI quirk with this view tree), so we keep the tip
            // visually lighter with a subtle leading border only.
            (
                Text(Image(systemName: "lightbulb")).foregroundStyle(.secondary)
                + Text("  ")
                + Text(text).foregroundStyle(.secondary)
            )
            .font(.system(size: 15))
            .lineSpacing(4)
            .multilineTextAlignment(.leading)
            .padding(.leading, 14)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.35))
                    .frame(width: 2)
            }

        case .important(let text):
            (
                Text(Image(systemName: "exclamationmark.triangle")).foregroundStyle(.orange)
                + Text("  ")
                + Text(text).foregroundStyle(.secondary)
            )
            .font(.system(size: 15))
            .lineSpacing(4)
            .multilineTextAlignment(.leading)
            .padding(.leading, 14)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(Color.orange.opacity(0.55))
                    .frame(width: 2)
            }

        case .keyCommand(let keys, let description):
            HStack(alignment: .center, spacing: 16) {
                HStack(spacing: 6) {
                    ForEach(Array(keys.enumerated()), id: \.offset) { _, key in
                        KeyCapView(label: key, size: .regular)
                    }
                }
                .frame(minWidth: 72, alignment: .leading)
                Text(description)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 4)

        case .kindaVimInstallStatus:
            KindaVimInstallStatusBlock()

        case .modeFlowNarrative:
            ModeFlowNarrativeView()

        case .modesDemo:
            ModesDemoView()
                .padding(.vertical, 4)

        case .modeIndicatorSpotlight:
            ModeIndicatorSpotlightView()
                .frame(minHeight: 320)

        case .linkTip(let symbol, let accent, let label, let url):
            linkTipView(symbol: symbol, accent: accent, label: label, url: url)

        case .image(let name, let size):
            bundleImage(named: name)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.25), radius: 14, y: 3)
                .padding(.vertical, 4)

        case .modePreview(let mode, let caption):
            HStack(spacing: 14) {
                ModeIndicatorView(mode: mode, isKindaVimRunning: true)
                Text(caption)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
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
                .background(AppColors.codeBackground, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }
}
