import AppKit
import SwiftUI

struct HelpBrowserView: View {
    let corpus: KindaVimHelpCorpus.Corpus
    @Binding var selectedTopicID: String?
    let currentLesson: Lesson?
    let chapters: [Chapter]
    let canGoBack: Bool
    var onGoBack: () -> Void
    var onSelectTopic: (String) -> Void
    var onOpenLesson: (String) -> Void
    var onAskQuestion: (HelpTopic, String) -> Void

    var body: some View {
        ScrollView {
            if let topic = selectedTopic {
                VStack(alignment: .leading, spacing: 18) {
                    if canGoBack {
                        Button(action: onGoBack) {
                            Label("Back", systemImage: "chevron.left")
                                .font(Typography.manualMetaValue)
                                .foregroundStyle(AppColors.manualAccent)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(AppColors.manualPanelBackground, in: Capsule())
                                .overlay {
                                    Capsule()
                                        .strokeBorder(AppColors.manualPanelBorder.opacity(0.8), lineWidth: 0.75)
                                }
                        }
                        .buttonStyle(.plain)
                        .pointingHandCursor()
                        .help("Back to previous manual topic")
                    }

                    Group {
                        if topic.id == "dedication" {
                            DedicationPageView()
                        } else {
                            HelpTopicDetailView(
                                topic: topic,
                                lessonRefs: lessonRefs(for: topic),
                                relatedTopics: topic.relatedTopicIDs.compactMap(corpus.topic(id:)),
                                onSelectTopic: { onSelectTopic($0.id) },
                                onOpenLesson: onOpenLesson,
                                onAskQuestion: { onAskQuestion(topic, $0) },
                                onOpenCommand: { command in
                                    if let match = corpus.topic(forCommand: command),
                                       match.id != topic.id {
                                        onSelectTopic(match.id)
                                    } else {
                                        onAskQuestion(topic, "Explain `\(command)`")
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 32)
                // 60pt clears the 14pt-top header-overlay (chat/manual
                // buttons + mode chip + stats rings), so content stops
                // cleanly below the header strip instead of scrolling
                // behind it.
                .padding(.top, 60)
                .padding(.bottom, 56)
                .frame(maxWidth: topic.id == "dedication" ? 920 : 720, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(AppColors.manualCanvasBackground)
        .onAppear {
            if selectedTopicID == nil {
                selectedTopicID = currentLesson.flatMap { corpus.topic(forLessonID: $0.id)?.id }
                    ?? corpus.topics.first?.id
            }
        }
    }

    private var selectedTopic: HelpTopic? {
        corpus.topic(id: selectedTopicID)
    }

    var railView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("REFERENCE")
                    .font(Typography.manualSectionLabel)
                    .tracking(Typography.manualTracking)
                    .foregroundStyle(AppColors.manualAccent)

                Text("Manual")
                    .font(Typography.manualRailTitle)
                    .tracking(-0.3)
                Text(currentLesson.map { "Suggested from \($0.title)" } ?? "A living manual with a dedication page and two sample command topics.")
                    .font(Typography.manualRailMeta)
                    .foregroundStyle(AppColors.manualMutedText)

                Spacer().frame(height: 8)

                ForEach(corpus.topics) { topic in
                    topicRow(topic)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 260)
        .background(AppColors.manualRailBackground)
    }

    private func topicRow(_ topic: HelpTopic) -> some View {
        Button {
            onSelectTopic(topic.id)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(topic.title)
                        .font(Typography.manualCardTitle)
                        .foregroundStyle(.primary)
                    if currentLesson.map({ topic.lessonIDs.contains($0.id) }) == true {
                        Text("NOW")
                            .font(Typography.manualSectionLabel)
                            .tracking(0.6)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(AppColors.manualAccent, in: Capsule())
                    }
                }
                Text(topic.summary)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColors.manualMutedText)
                    .lineLimit(2)

                if !topic.tags.isEmpty {
                    Text(topic.tags.prefix(3).joined(separator: "  "))
                        .font(Typography.manualCode)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(selectedTopicID == topic.id ? AppColors.manualAccent.opacity(0.12) : AppColors.manualPanelBackground)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(selectedTopicID == topic.id ? AppColors.manualAccent.opacity(0.35) : AppColors.manualPanelBorder.opacity(0.6), lineWidth: 0.75)
            }
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
    }

    private func lessonRefs(for topic: HelpTopic) -> [HelpLessonRef] {
        var refs: [HelpLessonRef] = []
        for chapter in chapters {
            for lesson in chapter.lessons where topic.lessonIDs.contains(lesson.id) {
                refs.append(.init(
                    id: lesson.id,
                    title: lesson.title,
                    chapterNumber: chapter.number,
                    lessonNumber: lesson.number
                ))
            }
        }
        return refs
    }
}

private struct HelpTopicDetailView: View {
    let topic: HelpTopic
    let lessonRefs: [HelpLessonRef]
    let relatedTopics: [HelpTopic]
    var onSelectTopic: (HelpTopic) -> Void
    var onOpenLesson: (String) -> Void
    var onAskQuestion: (String) -> Void
    /// Click handler for a command token (a tag, alias, or
    /// command-chip in the header). The parent resolves the string
    /// to a `HelpTopic` via `corpus.topic(forCommand:)` and either
    /// navigates or asks the chat.
    var onOpenCommand: (String) -> Void

    @State private var webResults: [WebResult] = []
    @State private var videoShorts: [VideoResult] = []
    @State private var videos: [VideoResult] = []
    @State private var customQuestion = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if topic.status == .unsupported {
                unsupportedBanner
            }
            header

            ForEach(topic.sections, id: \.title) { section in
                sectionView(section)
            }

            if !lessonRefs.isEmpty {
                relatedLessonsSection
            }

            askQuestionSection

            if !videoShorts.isEmpty || !videos.isEmpty || !webResults.isEmpty {
                resourcesSection
            }

            if !relatedTopics.isEmpty {
                relatedTopicsSection
            }
        }
        .task(id: topic.id) {
            await loadResources()
        }
    }

    /// Full-width warning banner rendered above the header when a
    /// topic covers a feature kindaVim doesn't implement. Clicking
    /// the banner opens kindaVim's public supported-commands docs
    /// in the default browser, so users can see the full
    /// compatibility matrix in one place.
    private var unsupportedBanner: some View {
        Button(action: { NSWorkspace.shared.open(KindaVimSupportCorpus.docsURL) }) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.red.opacity(0.85))
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Not Supported by kindaVim")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.primary)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    Text("This command isn't implemented in kindaVim. The entry below documents how it works in stock (terminal) Vim for reference. Click to see the full kindaVim support matrix.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.red.opacity(0.22), lineWidth: 0.75)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Open kindaVim's supported-commands documentation")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("REFERENCE ENTRY")
                        .font(Typography.manualSectionLabel)
                        .tracking(Typography.manualTracking)
                        .foregroundStyle(AppColors.manualAccent)

                    Text(topic.title)
                        .font(Typography.manualTopicTitle)
                        .tracking(-0.4)
                }

                Spacer()

                Text(topic.status.label.uppercased())
                    .font(Typography.manualSectionLabel)
                    .tracking(Typography.manualTracking)
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(statusColor.opacity(0.10), in: Capsule())
                    .overlay {
                        Capsule()
                            .strokeBorder(statusColor.opacity(0.28), lineWidth: 0.75)
                    }
            }

            AnnotatedText(
                string: topic.summary,
                font: Typography.manualSummary,
                capSize: .small,
                foregroundStyle: AppColors.manualMutedText,
                chipStyle: .inlineBadge
            )
            .lineLimit(nil)

            specGrid

            if !topic.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("COMMANDS")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(topic.tags, id: \.self) { tag in
                                Button(action: { onOpenCommand(tag) }) {
                                    KeyCapView(label: tag, size: .small)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .pointingHandCursor()
                                .help("Open reference for `\(tag)`")
                            }
                        }
                    }
                }
            }

            Rectangle()
                .fill(AppColors.manualPanelBorder.opacity(0.55))
                .frame(height: 1)
        }
        .padding(.bottom, 4)
    }

    private var specGrid: some View {
        VStack(alignment: .leading, spacing: 0) {
            specRow(label: "LOOKUP") {
                commandChips(Array(topic.tags.prefix(4)))
            }
            if !topic.aliases.isEmpty {
                specRow(label: "ALSO") {
                    commandChips(Array(topic.aliases.prefix(3)))
                }
            }
            if !lessonRefs.isEmpty {
                specRow(label: "PRACTICE") {
                    lessonChips(lessonRefs)
                }
            }
        }
        .background(AppColors.manualPanelBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(AppColors.manualPanelBorder.opacity(0.8), lineWidth: 0.75)
        }
    }

    private func specRow<Value: View>(
        label: String,
        @ViewBuilder value: () -> Value
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(label)
                .font(Typography.manualMetaKey)
                .tracking(Typography.manualTracking)
                .foregroundStyle(AppColors.manualAccent)
                .frame(width: 72, alignment: .leading)
            value()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.manualPanelBorder.opacity(0.45))
                .frame(height: 0.5)
        }
    }

    /// Horizontal row of clickable command pills used by the LOOKUP
    /// and ALSO rows. Each pill routes through `onOpenCommand`, which
    /// the parent resolves to either another help topic or a chat
    /// handoff when no matching topic exists.
    private func commandChips(_ commands: [String]) -> some View {
        HStack(spacing: 6) {
            ForEach(commands, id: \.self) { cmd in
                Button(action: { onOpenCommand(cmd) }) {
                    Text(cmd)
                        .font(Typography.manualMetaValue)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            AppColors.manualAccent.opacity(0.10),
                            in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(AppColors.manualAccent.opacity(0.28), lineWidth: 0.5)
                        }
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
                .help("Open reference for `\(cmd)`")
            }
        }
    }

    /// Inline clickable lesson pills for the PRACTICE row. Each pill
    /// labels with "chapter.lesson Title" and jumps to the lesson on
    /// click.
    private func lessonChips(_ refs: [HelpLessonRef]) -> some View {
        HStack(spacing: 6) {
            ForEach(refs) { ref in
                Button(action: { onOpenLesson(ref.id) }) {
                    HStack(spacing: 4) {
                        Text("\(ref.chapterNumber).\(ref.lessonNumber)")
                            .font(Typography.manualCode)
                            .foregroundStyle(.tertiary)
                            .monospacedDigit()
                        Text(ref.title)
                            .font(Typography.manualMetaValue)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        AppColors.manualAccent.opacity(0.10),
                        in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(AppColors.manualAccent.opacity(0.28), lineWidth: 0.5)
                    }
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
                .help("Open lesson \(ref.chapterNumber).\(ref.lessonNumber)")
            }
        }
    }

    private func sectionView(_ section: HelpTopicSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("SECTION")
            Text(section.title)
                .font(Typography.manualSectionTitle)

            ForEach(paragraphs(in: section.body), id: \.self) { paragraph in
                AnnotatedText(
                    string: paragraph,
                    font: Typography.manualBody,
                    capSize: .small,
                    foregroundStyle: .primary,
                    chipStyle: .inlineBadge
                )
                .textSelection(.enabled)
            }
        }
        .padding(16)
        .background(AppColors.manualPanelBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppColors.manualPanelBorder.opacity(0.7), lineWidth: 0.75)
        }
    }

    private var relatedLessonsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("RELATED LESSONS")
            VStack(spacing: 8) {
                ForEach(lessonRefs) { ref in
                    Button {
                        onOpenLesson(ref.id)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "book.fill")
                                .foregroundStyle(AppColors.manualAccent)
                            Text("\(ref.chapterNumber).\(ref.lessonNumber)")
                                .font(Typography.manualCode)
                                .foregroundStyle(.tertiary)
                                .monospacedDigit()
                            Text(ref.title)
                                .font(Typography.manualCardBody)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(12)
                        .background(AppColors.manualPanelBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(AppColors.manualPanelBorder.opacity(0.7), lineWidth: 0.75)
                        }
                    }
                    .buttonStyle(.plain)
                    .pointingHandCursor()
                }
            }
        }
    }

    private var askQuestionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("ASK A QUESTION")

            Text("Open chat from this topic with a concrete follow-up. The spike keeps the handoff simple, but it exercises the planned flow.")
                .font(Typography.manualCardBody)
                .foregroundStyle(AppColors.manualMutedText)

            if !topic.suggestedQuestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(topic.suggestedQuestions, id: \.self) { question in
                        Button {
                            onAskQuestion(question)
                        } label: {
                            HStack {
                                Text(question)
                                    .font(Typography.manualCardBody)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(10)
                            .background(AppColors.manualPanelBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(AppColors.manualPanelBorder.opacity(0.7), lineWidth: 0.75)
                            }
                        }
                        .buttonStyle(.plain)
                        .pointingHandCursor()
                    }
                }
            }

            HStack(spacing: 10) {
                TextField("Ask about this topic in chat", text: $customQuestion)
                    .textFieldStyle(.roundedBorder)
                Button("Ask") {
                    let trimmed = customQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    customQuestion = ""
                    onAskQuestion(trimmed)
                }
                .buttonStyle(.borderedProminent)
                .pointingHandCursor()
            }
        }
        .padding(16)
        .background(AppColors.manualPanelBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppColors.manualPanelBorder.opacity(0.7), lineWidth: 0.75)
        }
    }

    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("RELATED VIDEOS AND WEB PAGES")

            if !videoShorts.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 10) {
                        ForEach(videoShorts) { short in
                            VideoResultCard(result: short) {
                                NSWorkspace.shared.open(short.url)
                            }
                        }
                    }
                }
            }

            if !videos.isEmpty {
                VStack(spacing: 8) {
                    ForEach(videos) { video in
                        VideoResultCard(result: video) {
                            NSWorkspace.shared.open(video.url)
                        }
                    }
                }
            }

            if !webResults.isEmpty {
                VStack(spacing: 8) {
                    ForEach(webResults) { result in
                        WebResultCard(result: result) {
                            NSWorkspace.shared.open(result.url)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(AppColors.manualPanelBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppColors.manualPanelBorder.opacity(0.7), lineWidth: 0.75)
        }
    }

    private var relatedTopicsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("RELATED TOPICS")
            VStack(spacing: 0) {
                ForEach(Array(relatedTopics.enumerated()), id: \.element.id) { index, related in
                    Button {
                        onSelectTopic(related)
                    } label: {
                        HStack(spacing: 10) {
                            Text(related.tags.first ?? related.title)
                                .font(Typography.manualMetaValue)
                                .foregroundStyle(AppColors.manualAccent)
                                .frame(width: 86, alignment: .leading)
                            Text(related.title)
                                .font(Typography.manualCardBody)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .pointingHandCursor()
                    if index < relatedTopics.count - 1 {
                        Rectangle()
                            .fill(AppColors.manualPanelBorder.opacity(0.45))
                            .frame(height: 0.5)
                    }
                }
            }
        }
        .padding(16)
        .background(AppColors.manualPanelBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppColors.manualPanelBorder.opacity(0.7), lineWidth: 0.75)
        }
    }

    private var statusColor: Color {
        switch topic.status {
        case .supported: .green
        case .partial: .orange
        case .unsupported: .red
        }
    }

    private func paragraphs(in body: String) -> [String] {
        body
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Typography.manualSectionLabel)
            .tracking(Typography.manualTracking)
            .foregroundStyle(AppColors.manualAccent)
    }

    private func loadResources() async {
        webResults = []
        videoShorts = []
        videos = []

        async let webTask: [WebResult] = {
            guard let query = topic.webSearchQuery, !query.isEmpty else { return [] }
            return await WebSearchService.search(query)
        }()

        async let videoTask: (shorts: [VideoResult], videos: [VideoResult]) = {
            guard let query = topic.videoSearchQuery, !query.isEmpty else { return ([], []) }
            return await VideoSearchService.search(query)
        }()

        let (web, video) = await (webTask, videoTask)
        webResults = web
        videoShorts = video.shorts
        videos = video.videos
    }
}
