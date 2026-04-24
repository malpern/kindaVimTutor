#if canImport(FoundationModels)
import FoundationModels
#endif
import SwiftUI

/// Wraps Apple's on-device Foundation Models LLM for the "? ask a Vim
/// question" panel. Single thread, in-memory (resets on relaunch).
/// The system prompt pins the canonical Vim reference plus a short
/// kindaVim-specific note so the model doesn't answer about features
/// kindaVim doesn't actually implement.
///
/// The assistant streams structured `VimAnswer` responses so the
/// view can render answer / related-motions / faster-alternative as
/// separate lesson-style cards. Supplementary web results are fired
/// after the answer completes, only when the model requests them via
/// `VimAnswer.webSearchQuery`.
@MainActor
@Observable
final class ChatEngine {
    enum Availability {
        case notSupported          // pre-macOS 26
        case notEnabled            // macOS 26 but Apple Intelligence is off
        case ready
    }

    var messages: [ChatMessage] = []
    var input: String = ""
    var isResponding: Bool = false

    private(set) var availability: Availability
    private var currentLesson: Lesson?
    private var currentChapterTitle: String?
    private var currentHelpTopicID: String?
    private var chapters: [Chapter] = []

    #if canImport(FoundationModels)
    @ObservationIgnored private var sessionStorage: Any?
    #endif

    init() {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available: availability = .ready
            default:         availability = .notEnabled
            }
        } else {
            availability = .notSupported
        }
        #else
        availability = .notSupported
        #endif
    }

    /// Called by the app when the user opens the chat panel. Seeds
    /// the greeting bubble and (if available) primes the session with
    /// the current lesson context as part of the system prompt.
    func activate(
        lesson: Lesson?,
        chapterTitle: String?,
        chapters: [Chapter],
        helpTopicID: String? = nil
    ) {
        currentLesson = lesson
        currentChapterTitle = chapterTitle
        currentHelpTopicID = helpTopicID
        self.chapters = chapters

        if messages.isEmpty {
            messages.append(ChatMessage(
                role: .assistant,
                payload: .text("What Vim questions do you have?")
            ))
        }

        #if canImport(FoundationModels)
        if #available(macOS 26.0, *), availability == .ready, sessionStorage == nil {
            let session = LanguageModelSession(instructions: systemInstructions())
            session.prewarm()
            sessionStorage = session
        }
        #endif
    }

    /// Sends the user's current `input`, appends it as a user
    /// message, and replies — preferring a pre-authored canonical
    /// answer from the help corpus when one matches, falling back
    /// to the on-device model for everything else.
    func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isResponding else { return }
        input = ""
        messages.append(ChatMessage(role: .user, payload: .text(text)))

        if let canonical = CanonicalAnswerLookup.match(
            for: text,
            in: KindaVimHelpCorpus.topics,
            preferredTopicID: currentHelpTopicID
        ) {
            appendCanonicalAnswer(canonical.qa, topic: canonical.topic)
            return
        }

        if let topic = KindaVimHelpCorpus.topic(
            forQuery: text,
            preferredTopicID: currentHelpTopicID
        ) {
            appendTopicReferenceAnswer(topic)
            return
        }

        #if canImport(FoundationModels)
        if #available(macOS 26.0, *), availability == .ready {
            Task { await streamReply(to: text) }
            return
        }
        #endif

        messages.append(ChatMessage(
            role: .assistant,
            payload: .text(fallbackReply())
        ))
    }

    /// Renders a pre-authored canonical Q&A directly into the
    /// thread. No model call, instant response. The "From reference"
    /// badge on the bubble signals the curated source.
    private func appendCanonicalAnswer(_ qa: CanonicalQA, topic: HelpTopic) {
        let display = VimAnswerDisplay(
            answer: qa.answer,
            relatedCommands: qa.relatedCommands.map {
                VimAnswerDisplay.RelatedCommandDisplay(
                    command: $0.command,
                    summary: $0.summary
                )
            },
            fasterAlternative: qa.fasterAlternative,
            webSearchQuery: nil,
            videoSearchQuery: nil,
            isUnsupported: qa.isUnsupported,
            terminalVimExplanation: qa.terminalVimExplanation,
            isCanonical: true
        )
        var bubble = ChatMessage(
            role: .assistant,
            payload: .answer(display)
        )
        bubble.canonicalSource = ChatMessage.CanonicalSource(
            topicID: topic.id,
            topicTitle: topic.title
        )
        // Surface the topic behind the answer so the user can still
        // deep-read, mirroring the model path's curriculum lookup.
        if let lessonId = CurriculumLookup
            .matches(for: qa.answer, chapters: chapters)
            .first(where: { _ in true })?.id,
           let chapter = chapters.first(where: {
               $0.lessons.contains(where: { $0.id == lessonId })
           }),
           let lesson = chapter.lessons.first(where: { $0.id == lessonId }) {
            bubble.relatedLessons = [
                ChatMessage.RelatedLessonRef(
                    id: lessonId,
                    title: lesson.title,
                    chapterNumber: chapter.number,
                    lessonNumber: lesson.number
                )
            ]
        }
        messages.append(bubble)
        let index = messages.count - 1

        // Canonical answers still deserve supplementary context —
        // fire the topic-level web/video queries so the user sees
        // articles + YouTube clips alongside the curated answer.
        // Bypass the fetch when the feature is unsupported since
        // those queries surface stock-Vim content irrelevant here.
        let webQuery = qa.isUnsupported ? nil : topic.webSearchQuery
        let videoQuery = qa.isUnsupported ? nil : topic.videoSearchQuery
        if webQuery != nil || videoQuery != nil {
            Task { [weak self] in
                await self?.fetchSupplementaryResultsForCanonical(
                    webQuery: webQuery,
                    videoQuery: videoQuery,
                    messageIndex: index
                )
            }
        }
    }

    /// Deterministic topic-level fallback when the user clearly
    /// asked about a documented command/concept but there was no
    /// exact canonical Q&A match. This keeps common lookups like
    /// `ci"` or "inside word" off the model path entirely.
    private func appendTopicReferenceAnswer(_ topic: HelpTopic) {
        let related = topic.tags
            .filter { !$0.isEmpty && $0 != topic.id }
            .prefix(4)
            .map {
                VimAnswerDisplay.RelatedCommandDisplay(
                    command: $0,
                    summary: topic.title
                )
            }

        var display = VimAnswerDisplay(
            answer: topic.summary + " Open the Manual entry for the full reference.",
            relatedCommands: Array(related),
            fasterAlternative: nil,
            webSearchQuery: nil,
            videoSearchQuery: nil,
            isUnsupported: topic.status == .unsupported,
            terminalVimExplanation: nil,
            isCanonical: true
        )

        if topic.status == .unsupported,
           let unsupportedQA = topic.canonicalQA.first(where: { $0.isUnsupported }) {
            display.answer = unsupportedQA.answer
            display.relatedCommands = unsupportedQA.relatedCommands.map {
                VimAnswerDisplay.RelatedCommandDisplay(
                    command: $0.command,
                    summary: $0.summary
                )
            }
            display.terminalVimExplanation = unsupportedQA.terminalVimExplanation
        }

        var bubble = ChatMessage(
            role: .assistant,
            payload: .answer(display)
        )
        bubble.canonicalSource = ChatMessage.CanonicalSource(
            topicID: topic.id,
            topicTitle: topic.title
        )
        messages.append(bubble)
        let index = messages.count - 1

        let webQuery = display.isUnsupported ? nil : topic.webSearchQuery
        let videoQuery = display.isUnsupported ? nil : topic.videoSearchQuery
        if webQuery != nil || videoQuery != nil {
            Task { [weak self] in
                await self?.fetchSupplementaryResultsForCanonical(
                    webQuery: webQuery,
                    videoQuery: videoQuery,
                    messageIndex: index
                )
            }
        }
    }

    /// Non-@available wrapper so canonical answers can trigger web
    /// and video fetches on any macOS. The searches themselves are
    /// pure Swift + Python fallback and don't require Foundation
    /// Models.
    private func fetchSupplementaryResultsForCanonical(
        webQuery: String?,
        videoQuery: String?,
        messageIndex index: Int
    ) async {
        async let webTask: [WebResult] = {
            guard let q = webQuery, !q.isEmpty else { return [] }
            return await WebSearchService.search(q)
        }()
        async let videoTask: (shorts: [VideoResult], videos: [VideoResult]) = {
            guard let q = videoQuery, !q.isEmpty else { return ([], []) }
            return await VideoSearchService.search(q)
        }()
        let (web, video) = await (webTask, videoTask)

        guard index < messages.count else { return }
        var withResults = messages[index]
        withResults.webResults = web
        withResults.videoShorts = video.shorts
        withResults.videos = video.videos
        messages[index] = withResults
    }

    #if canImport(FoundationModels)
    @available(macOS 26.0, *)
    private func streamReply(to userText: String) async {
        guard let session = sessionStorage as? LanguageModelSession else { return }
        isResponding = true
        defer { isResponding = false }

        var bubble = ChatMessage(
            role: .assistant,
            payload: .answer(VimAnswerDisplay()),
            isStreaming: true
        )
        messages.append(bubble)
        let index = messages.count - 1

        do {
            let stream = session.streamResponse(
                to: userText,
                generating: VimAnswer.self
            )
            for try await snapshot in stream {
                bubble.payload = .answer(display(from: snapshot.content, userQuery: userText))
                messages[index] = bubble
            }

            // Finalize: use `asFinalResult()` when possible to grab a
            // non-optional response, else keep the last snapshot.
            if case .answer(let final) = bubble.payload {
                bubble.isStreaming = false
                bubble.relatedLessons = CurriculumLookup
                    .matches(for: final.answer, chapters: chapters)
                    .compactMap { lesson in
                        guard let chapter = chapters.first(where: {
                            $0.lessons.contains(where: { $0.id == lesson.id })
                        }) else { return nil }
                        return ChatMessage.RelatedLessonRef(
                            id: lesson.id,
                            title: lesson.title,
                            chapterNumber: chapter.number,
                            lessonNumber: lesson.number
                        )
                    }
                messages[index] = bubble

                await fetchSupplementaryResults(
                    webQuery: final.webSearchQuery,
                    videoQuery: final.videoSearchQuery,
                    messageIndex: index
                )
            }
        } catch {
            AppLogger.shared.error("chat", "streamFailed", fields: [
                "query": userText,
                "error": String(describing: error)
            ])
            bubble.payload = .text(
                "I couldn't answer that one — try rephrasing, or check the Vim reference directly."
            )
            bubble.isStreaming = false
            messages[index] = bubble
        }
    }

    /// Kicks off web-article and YouTube searches in parallel based
    /// on whether the model populated the respective query fields,
    /// then updates the assistant bubble with whatever came back.
    @available(macOS 26.0, *)
    private func fetchSupplementaryResults(
        webQuery: String?,
        videoQuery: String?,
        messageIndex index: Int
    ) async {
        async let webTask: [WebResult] = {
            guard let q = webQuery, !q.isEmpty else { return [] }
            return await WebSearchService.search(q)
        }()
        async let videoTask: (shorts: [VideoResult], videos: [VideoResult]) = {
            guard let q = videoQuery, !q.isEmpty else { return ([], []) }
            return await VideoSearchService.search(q)
        }()
        let (web, video) = await (webTask, videoTask)

        guard index < messages.count else { return }
        var withResults = messages[index]
        withResults.webResults = web
        withResults.videoShorts = video.shorts
        withResults.videos = video.videos
        messages[index] = withResults
    }

    @available(macOS 26.0, *)
    private func display(
        from partial: VimAnswer.PartiallyGenerated,
        userQuery: String
    ) -> VimAnswerDisplay {
        let modelSaysUnsupported = partial.isUnsupported ?? false
        let resolvedUnsupported = Self.resolveUnsupported(
            modelFlag: modelSaysUnsupported,
            userQuery: userQuery,
            answer: partial.answer ?? ""
        )
        return VimAnswerDisplay(
            answer: partial.answer ?? "",
            relatedCommands: Self.dedupeRelatedCommands(
                partial.relatedCommands ?? [],
                against: partial.answer ?? ""
            ),
            fasterAlternative: partial.fasterAlternative ?? nil,
            webSearchQuery: partial.webSearchQuery ?? nil,
            videoSearchQuery: partial.videoSearchQuery ?? nil,
            isUnsupported: resolvedUnsupported,
            terminalVimExplanation: resolvedUnsupported
                ? (partial.terminalVimExplanation ?? nil)
                : nil
        )
    }

    /// Overrides the model's `isUnsupported` flag when it contradicts
    /// the authoritative `KindaVimSupportCorpus`. The 3B on-device
    /// model sometimes flags supported commands as unsupported (or
    /// vice-versa); trusting the corpus prevents the UI from
    /// rendering a red "Not Supported" card for commands like `u`
    /// that clearly work.
    private static func resolveUnsupported(
        modelFlag: Bool,
        userQuery: String,
        answer: String
    ) -> Bool {
        let corpus = KindaVimSupportCorpus.shared
        let tokens = extractCommandTokens(from: userQuery + " " + answer)

        // Explicit unsupported command in the question or answer
        // wins — show the red card no matter what the model said.
        if tokens.contains(where: { corpus.isExplicitlyUnsupported($0) }) {
            return true
        }
        // If the model flagged unsupported but every command we
        // can identify is supported, override back to false.
        if modelFlag {
            let known = tokens.filter { corpus.isKnownCommand($0) }
            let allSupported = !known.isEmpty
                && !known.contains(where: { corpus.isExplicitlyUnsupported($0) })
            if allSupported { return false }
        }
        return modelFlag
    }

    private static func extractCommandTokens(from text: String) -> [String] {
        var out: [String] = []
        var cursor = text.startIndex
        while cursor < text.endIndex {
            if text[cursor] == "`" {
                let after = text.index(after: cursor)
                if let close = text[after...].firstIndex(of: "`") {
                    out.append(String(text[after..<close]))
                    cursor = text.index(after: close)
                    continue
                }
            }
            cursor = text.index(after: cursor)
        }
        return out
    }

    /// Strip any related command that already appears in the answer,
    /// is missing a command/summary, or is a duplicate of another
    /// entry — keeps the list scannable and avoids `dw` showing up
    /// as a related command on a `dw` answer.
    @available(macOS 26.0, *)
    private static func dedupeRelatedCommands(
        _ partials: [RelatedCommand.PartiallyGenerated],
        against answer: String
    ) -> [VimAnswerDisplay.RelatedCommandDisplay] {
        let answerTokens = tokenize(answer)
        var seen: Set<String> = []
        var out: [VimAnswerDisplay.RelatedCommandDisplay] = []
        for partial in partials {
            let command = (partial.command ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !command.isEmpty,
                  !answerTokens.contains(command),
                  !seen.contains(command) else { continue }
            seen.insert(command)
            out.append(.init(
                command: command,
                summary: (partial.summary ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            ))
        }
        return out
    }

    private static func tokenize(_ text: String) -> Set<String> {
        // Pull backtick-wrapped tokens (`dw`, `Esc`, `ci"`) and any
        // bare short alphanumeric word from the answer so we can
        // compare against related-motion entries.
        var tokens: Set<String> = []
        var i = text.startIndex
        while i < text.endIndex {
            if text[i] == "`" {
                let after = text.index(after: i)
                if let close = text[after...].firstIndex(of: "`") {
                    tokens.insert(String(text[after..<close]))
                    i = text.index(after: close)
                    continue
                }
            }
            i = text.index(after: i)
        }
        return tokens
    }
    #endif

    struct PromptDebugSnapshot {
        let text: String
        let estimatedTokenCount: Int
    }

    func debugPromptSnapshot() -> PromptDebugSnapshot {
        let text = systemInstructions()
        return PromptDebugSnapshot(
            text: text,
            estimatedTokenCount: Self.estimatedTokenCount(for: text)
        )
    }

    static func estimatedTokenCount(for text: String) -> Int {
        let collapsed = text.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        )
        // Foundation Models tokenization is proprietary, but in
        // practice this prompt tracks close to ~3.5 UTF-16 code
        // units per token. Bias slightly high so the guard test
        // fails before we hit the 4096-token hard limit at runtime.
        return Int(ceil(Double(collapsed.utf16.count) / 3.4))
    }

    private func systemInstructions() -> String {
        var prompt = """
        You are a concise Vim tutor embedded inside the kindaVim Tutor macOS app.
        Answer briefly, accurately, and with concrete examples.
        Prefer kindaVim behavior over stock Vim behavior.

        ## Output rules
        - Wrap keys and command sequences in backticks: `Esc`, `dw`, `ci"`.
        - Use `{{normal}}`, `{{insert}}`, `{{visual}}` for modes.
        - Say "Press" for one key and "Type" for multi-key sequences.
        - For comparison questions, define each command first, then state the difference.

        ## Grounding rules
        - If the user asks about a specific command, answer about that command.
        - Do not invent support. If unsure, say so briefly.
        - If the command is listed as unsupported below, set `isUnsupported` to true.
        - For unsupported commands, keep `answer` short and definitive, and put any stock-Vim explanation in `terminalVimExplanation`.

        \(KindaVimSupportCorpus.asPromptBlock())

        ## Supplementary search
        Populate `webSearchQuery` only when external tutorials would help.
        Leave it null for self-contained single-command answers.
        Include the word "tutorial" when a video walkthrough would help.

        """
        if let lesson = currentLesson, let chapter = currentChapterTitle {
            prompt.append("""

            ## Current lesson context
            The user is on chapter "\(chapter)", lesson "\(lesson.title)".

            """)
        }
        // Give the model only the currently viewed manual topic.
        // Canonical retrieval and deterministic topic lookup handle
        // the rest; trying to inline the whole manual overruns the
        // 3B model's 4096-token context window.
        prompt.append("\n## kindaVim manual\n\n")
        prompt.append(Self.helpCorpusBlock(currentTopicID: currentHelpTopicID))
        return prompt
    }

    /// Serializes the in-app help corpus as grounding context.
    /// The currently-viewed topic is embedded FULLY (title + tags +
    /// summary + every section body). All other topics shrink to a
    /// one-line index entry so the prompt stays compact and the
    /// on-device model's context window isn't overrun.
    private static func helpCorpusBlock(currentTopicID: String?) -> String {
        let topics = KindaVimHelpCorpus.topics
        var lines: [String] = []

        if let id = currentTopicID,
           let current = topics.first(where: { $0.id == id }) {
            lines.append("### \(current.title) (currently viewed)")
            if !current.tags.isEmpty {
                lines.append("commands: " + current.tags.joined(separator: ", "))
            }
            if !current.aliases.isEmpty {
                lines.append("aliases: " + current.aliases.joined(separator: ", "))
            }
            lines.append("summary: " + current.summary)
            for section in current.sections {
                lines.append("")
                lines.append("#### \(section.title)")
                lines.append(section.body)
            }
            lines.append("")
        }

        if currentTopicID == nil {
            lines.append("No specific manual topic is currently open.")
        }
        return lines.joined(separator: "\n")
    }

    private func fallbackReply() -> String {
        switch availability {
        case .notSupported:
            return "Live answers need macOS 26 and Apple Intelligence. You're on an older macOS — open System Settings → General → Software Update to get macOS 26."
        case .notEnabled:
            return "Apple Intelligence isn't turned on. Open System Settings → Apple Intelligence & Siri to enable it, then reopen this panel."
        case .ready:
            return "I couldn't answer that one — try rephrasing, or open the Manual for the canonical kindaVim reference."
        }
    }
}
