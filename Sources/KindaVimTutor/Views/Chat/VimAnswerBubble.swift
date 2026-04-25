import SwiftUI

/// Lesson-style rendering of an assistant `VimAnswerDisplay`. Sits
/// left-aligned like a chat bubble but uses the same visual grammar
/// as `ExplanationView` so the chat feels continuous with lessons.
struct VimAnswerBubble: View {
    let display: VimAnswerDisplay
    var isStreaming: Bool = false
    var relatedLessons: [ChatMessage.RelatedLessonRef] = []
    var canonicalSource: ChatMessage.CanonicalSource? = nil
    var onOpenLesson: ((String) -> Void)? = nil
    var onOpenURL: ((URL) -> Void)? = nil
    var onAskAboutMotion: ((String) -> Void)? = nil
    var onOpenHelpTopic: ((String) -> Void)? = nil
    var onPractice: (() -> Void)? = nil
    var webResults: [WebResult] = []
    var videoShorts: [VideoResult] = []
    var videos: [VideoResult] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if display.isCanonical, !display.answer.isEmpty {
                canonicalSourceBadge
            }
            if display.isUnsupported {
                unsupportedCard
                if let tv = display.terminalVimExplanation, !tv.isEmpty {
                    terminalVimCard(text: tv)
                }
            } else {
                answerCard
            }
            if let onPractice {
                practiceButton(onPractice)
            }
            if !display.relatedCommands.isEmpty {
                relatedCommandsSection
            }
            if let faster = display.fasterAlternative,
               Self.isMeaningfulFasterTip(faster, vs: display.answer) {
                fasterTipCard(text: faster)
            }
            if !relatedLessons.isEmpty {
                relatedLessonsSection
            }
            if !videoShorts.isEmpty {
                videoShortsSection
            }
            if !videos.isEmpty {
                videosSection
            }
            if !webResults.isEmpty {
                webResultsSection
            }
        }
        .frame(maxWidth: 520, alignment: .leading)
    }

    /// Generates an on-the-fly drill for the concept this bubble
    /// explains. Only shown when OpenAI is the configured backend —
    /// gated upstream by `ChatView.shouldOfferPractice(for:)`.
    private func practiceButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "play.circle")
                    .font(.system(size: 13, weight: .semibold))
                Text("Practice this concept")
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.accentColor.opacity(0.15),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .foregroundStyle(Color.accentColor)
        }
        .buttonStyle(.plain)
        .help("Generate a short drill for this concept")
    }

    /// Small provenance chip that marks answers pulled from the
    /// pre-authored canonical corpus. When a source topic is known,
    /// the chip becomes a Button that opens that topic in the
    /// manual so the user can read the full reference entry.
    @ViewBuilder
    private var canonicalSourceBadge: some View {
        if let source = canonicalSource, let open = onOpenHelpTopic {
            Button(action: { open(source.topicID) }) {
                canonicalBadgeContent(trailingLabel: source.topicTitle, trailingChevron: true)
            }
            .buttonStyle(.plain)
            .help("Open “\(source.topicTitle)” in the manual")
        } else {
            canonicalBadgeContent(trailingLabel: nil, trailingChevron: false)
        }
    }

    private func canonicalBadgeContent(
        trailingLabel: String?,
        trailingChevron: Bool
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 10, weight: .semibold))
            Text("From reference")
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.3)
            if let trailingLabel {
                Text("·")
                    .font(.system(size: 10))
                    .opacity(0.5)
                Text(trailingLabel)
                    .font(.system(size: 10, weight: .medium))
            }
            if trailingChevron {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 8, weight: .bold))
                    .opacity(0.8)
            }
        }
        .foregroundStyle(Color.green.opacity(0.85))
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Color.green.opacity(0.12),
            in: Capsule()
        )
    }

    /// Definitive "Not Supported in kindaVim" card. Renders the
    /// answer body (usually a one-sentence statement + closest
    /// supported alternative) under a red-tinted header so the
    /// user immediately sees the non-support.
    private var unsupportedCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "xmark.octagon.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.red.opacity(0.85))
                Text("Not Supported in kindaVim")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.red.opacity(0.9))
            }
            if !display.answer.isEmpty {
                AnnotatedText(
                    string: display.answer,
                    font: .system(size: 14),
                    capSize: .small,
                    foregroundStyle: .primary,
                    chipStyle: .inlineBadge
                )
                .lineSpacing(4)
                .textSelection(.enabled)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.red.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.red.opacity(0.22), lineWidth: 0.75)
        }
    }

    /// Paired informational card that explains how the feature
    /// works in stock terminal Vim, for users who might drop into
    /// `vim` in Terminal. Neutral blue tint so it reads as
    /// reference context, not another warning.
    private func terminalVimCard(text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.blue.opacity(0.85))
                Text("Terminal Vim")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.blue.opacity(0.9))
            }
            AnnotatedText(
                string: text,
                font: .system(size: 13),
                capSize: .small,
                foregroundStyle: .primary,
                chipStyle: .inlineBadge
            )
            .lineSpacing(4)
            .textSelection(.enabled)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.blue.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.blue.opacity(0.22), lineWidth: 0.75)
        }
    }

    // MARK: - Filtering

    /// The on-device model will sometimes fill `fasterAlternative`
    /// with a null-equivalent phrase ("there's no faster way",
    /// "same as above", a near-duplicate of the answer) even when
    /// told to leave it blank. Strip those so the tip card only
    /// appears when there's a real tip.
    private static func isMeaningfulFasterTip(_ text: String, vs answer: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 12 else { return false }
        let lower = trimmed.lowercased()
        let noisePhrases = [
            "no faster", "not faster", "no quicker", "no other way",
            "n/a", "none", "same as", "same approach", "already the",
            "this is already", "there is no", "there isn't"
        ]
        if noisePhrases.contains(where: { lower.contains($0) }) {
            return false
        }
        // Reject if the tip is just the answer restated.
        let answerLower = answer.lowercased()
        if !answerLower.isEmpty, lower == answerLower {
            return false
        }
        return true
    }

    // MARK: - Sections

    private var answerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if display.answer.isEmpty && isStreaming {
                TypingDotsCompact()
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            } else {
                AnnotatedText(
                    string: display.answer,
                    font: .system(size: 14),
                    capSize: .small,
                    foregroundStyle: .primary,
                    chipStyle: .inlineBadge
                )
                .lineSpacing(4)
                .textSelection(.enabled)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    /// Related commands are split into two groups by support status.
    /// Supported commands appear under the neutral "Related
    /// Commands" label first. Unsupported ones fall into a red
    /// "Not Supported in kindaVim" group so the user doesn't confuse
    /// "works here" with "works in stock Vim only."
    private var relatedCommandsSection: some View {
        let corpus = KindaVimSupportCorpus.shared
        let (supported, unsupported) = splitRelatedCommands(
            display.relatedCommands, corpus: corpus
        )
        return VStack(alignment: .leading, spacing: 12) {
            if !supported.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("RELATED COMMANDS")
                    VStack(spacing: 6) {
                        ForEach(supported, id: \.command) { cmd in
                            relatedCommandRow(cmd, isUnsupported: false)
                        }
                    }
                }
            }
            if !unsupported.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    unsupportedSectionLabel
                    VStack(spacing: 6) {
                        ForEach(unsupported, id: \.command) { cmd in
                            relatedCommandRow(cmd, isUnsupported: true)
                        }
                    }
                }
            }
        }
        .padding(.leading, 2)
    }

    /// Split by explicit unsupported-corpus membership. "Unknown"
    /// tokens stay in the supported bucket — we don't want to flag
    /// things like `Cmd+V` or random prose tokens as unsupported.
    private func splitRelatedCommands(
        _ items: [VimAnswerDisplay.RelatedCommandDisplay],
        corpus: KindaVimSupportCorpus.Corpus
    ) -> (supported: [VimAnswerDisplay.RelatedCommandDisplay],
          unsupported: [VimAnswerDisplay.RelatedCommandDisplay]) {
        var sup: [VimAnswerDisplay.RelatedCommandDisplay] = []
        var unsup: [VimAnswerDisplay.RelatedCommandDisplay] = []
        for item in items {
            if corpus.isExplicitlyUnsupported(item.command) {
                unsup.append(item)
            } else {
                sup.append(item)
            }
        }
        return (sup, unsup)
    }

    private var unsupportedSectionLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: "xmark.octagon.fill")
                .font(.system(size: 11, weight: .semibold))
            Text("Not Supported in kindaVim")
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundStyle(Color.red.opacity(0.9))
    }

    private func relatedCommandRow(
        _ cmd: VimAnswerDisplay.RelatedCommandDisplay,
        isUnsupported: Bool
    ) -> some View {
        Button(action: { onAskAboutMotion?(cmd.command) }) {
            HStack(spacing: 14) {
                KeyCapView(label: cmd.command, size: .small)
                Text(cmd.summary)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "arrow.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                rowBackground(isUnsupported: isUnsupported),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(rowBorder(isUnsupported: isUnsupported),
                                  lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .help(isUnsupported
              ? "Not supported in kindaVim — explain `\(cmd.command)`"
              : "Explain `\(cmd.command)`")
    }

    private func rowBackground(isUnsupported: Bool) -> Color {
        isUnsupported ? Color.red.opacity(0.08) : Color.primary.opacity(0.04)
    }

    private func rowBorder(isUnsupported: Bool) -> Color {
        isUnsupported ? Color.red.opacity(0.22) : Color.primary.opacity(0.06)
    }

    private func fasterTipCard(text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.yellow.opacity(0.85))
                .frame(width: 16, alignment: .topLeading)
                .padding(.top, 2)
            AnnotatedText(
                string: text,
                font: .system(size: 13),
                capSize: .small,
                foregroundStyle: .primary,
                chipStyle: .inlineBadge
            )
            .lineSpacing(3)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(AppColors.tipBackground,
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var relatedLessonsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("RELATED LESSONS")
            VStack(spacing: 6) {
                ForEach(relatedLessons) { ref in
                    lessonRow(ref: ref)
                }
            }
        }
        .padding(.leading, 2)
    }

    private func lessonRow(ref: ChatMessage.RelatedLessonRef) -> some View {
        Button(action: { onOpenLesson?(ref.id) }) {
            HStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("\(ref.chapterNumber).\(ref.lessonNumber)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
                Text(ref.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "arrow.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.04),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
    }

    private var webResultsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("WEB")
            VStack(spacing: 6) {
                ForEach(webResults) { result in
                    WebResultCard(result: result, onOpen: {
                        onOpenURL?(result.url)
                    })
                }
            }
        }
        .padding(.leading, 2)
    }

    private var videoShortsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("SHORTS")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(videoShorts) { short in
                        VideoResultCard(result: short, onOpen: {
                            onOpenURL?(short.url)
                        })
                    }
                }
            }
        }
        .padding(.leading, 2)
    }

    private var videosSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("VIDEOS")
            VStack(spacing: 6) {
                ForEach(videos) { video in
                    VideoResultCard(result: video, onOpen: {
                        onOpenURL?(video.url)
                    })
                }
            }
        }
        .padding(.leading, 2)
    }

    /// Section label styled to match the page-level title family:
    /// plain sans-serif, sentence case, no tracking. Keeps the chat
    /// typographically consistent with lesson headings instead of
    /// looking like a separate monospaced section-label system.
    private func sectionLabel(_ text: String) -> some View {
        Text(sectionLabelText(text))
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)
    }

    /// Convert ALL-CAPS label keys into Sentence Case for display.
    private func sectionLabelText(_ raw: String) -> String {
        raw.split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
}

private struct TypingDotsCompact: View {
    @State private var phase = 0
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.primary.opacity(0.5))
                    .frame(width: 6, height: 6)
                    .scaleEffect(phase == i ? 1.15 : 0.85)
                    .opacity(phase == i ? 1 : 0.6)
            }
        }
        .onAppear {
            Task { @MainActor in
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(350))
                    withAnimation(.easeInOut(duration: 0.3)) {
                        phase = (phase + 1) % 3
                    }
                }
            }
        }
    }
}
