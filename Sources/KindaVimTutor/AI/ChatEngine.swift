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

        let canonicalMatch = CanonicalAnswerLookup.match(
            for: text,
            in: KindaVimHelpCorpus.topics,
            preferredTopicID: currentHelpTopicID
        )
        let topicMatch = canonicalMatch?.topic
            ?? KindaVimHelpCorpus.topic(
                forQuery: text,
                preferredTopicID: currentHelpTopicID
            )

        // When OpenAI is the backend, don't short-circuit — instead
        // inject the matched reference into the system prompt so the
        // model answers the user's exact phrasing while staying
        // grounded in our authored content.
        if AIBackendSettings.backend == .openAI {
            if let key = AIBackendSettings.openAIKey {
                // Pull top-3 related topics (including the best match).
                // Questions often span concepts ("can I undo after dd?"
                // touches Delete and Undo) — multi-topic grounding
                // reduces guessing.
                let referenceTopics = KindaVimHelpCorpus.topics(
                    forQuery: text,
                    limit: 3,
                    preferredTopicID: currentHelpTopicID
                )
                logQuery(
                    text,
                    tier: "model-openai",
                    topicID: topicMatch?.id,
                    extra: canonicalMatch.map { [
                        "score": String(format: "%.2f", $0.score)
                    ] } ?? [:]
                )
                Task { [referenceTopics, canonicalMatch, topicMatch] in
                    await streamOpenAIReply(
                        to: text,
                        apiKey: key,
                        referenceTopic: topicMatch,
                        referenceTopics: referenceTopics,
                        referenceQA: canonicalMatch?.qa
                    )
                }
                return
            }
            logQuery(text, tier: "openai-missing-key")
            messages.append(ChatMessage(
                role: .assistant,
                payload: .text(
                    "Add an OpenAI API key in Settings → Chat AI (or set OPENAI_API_KEY in the environment), or switch back to Apple Intelligence."
                )
            ))
            return
        }

        if let canonical = canonicalMatch {
            logQuery(text, tier: "canonical", topicID: canonical.topic.id,
                     extra: ["score": String(format: "%.2f", canonical.score)])
            appendCanonicalAnswer(canonical.qa, topic: canonical.topic)
            return
        }

        if let topic = topicMatch {
            logQuery(text, tier: "topic-reference", topicID: topic.id)
            appendTopicReferenceAnswer(topic)
            return
        }

        #if canImport(FoundationModels)
        if #available(macOS 26.0, *), availability == .ready {
            logQuery(text, tier: "model")
            Task { await streamReply(to: text) }
            return
        }
        #endif

        logQuery(text, tier: "unavailable-fallback")
        messages.append(ChatMessage(
            role: .assistant,
            payload: .text(fallbackReply())
        ))
    }

    /// Logs each chat query + which retrieval tier served it. Gives us
    /// a feed of real user questions to triage: queries hitting
    /// `topic-reference` or `model` repeatedly are good candidates for
    /// new canonical Q&As. Field names deliberately short to keep log
    /// lines readable.
    private func logQuery(
        _ query: String,
        tier: String,
        topicID: String? = nil,
        extra: [String: String] = [:]
    ) {
        var fields: [String: String] = [
            "tier": tier,
            "query": query,
            "viewing": currentHelpTopicID ?? "",
            "lesson": currentLesson?.id ?? ""
        ]
        if let topicID { fields["topic"] = topicID }
        fields.merge(extra) { _, new in new }
        AppLogger.shared.info("chat", "query", fields: fields)
    }

    /// Build a "Reference for this question" block to append to the
    /// OpenAI system prompt. Grounds the model in the top-N matched
    /// topics' authored content so its answer stays aligned with our
    /// reference while still being tailored to the user's exact
    /// phrasing. Including multiple topics helps when a question
    /// spans concepts (e.g. "undo after dd" needs both Delete and
    /// Undo/Redo).
    ///
    /// Returns an empty string when there are no references, so
    /// concatenating it is always safe.
    static func referenceBlock(
        topics: [HelpTopic], qa: CanonicalQA?
    ) -> String {
        guard !topics.isEmpty || qa != nil else { return "" }
        var parts: [String] = [
            "",
            "---",
            "Reference for this question (AUTHORED — answer the user's",
            "exact phrasing, but ground every fact in these references;",
            "do not contradict them):",
        ]
        for topic in topics {
            parts.append("")
            parts.append("### \(topic.title)")
            if !topic.tags.isEmpty {
                parts.append("commands: " + topic.tags.joined(separator: ", "))
            }
            let summary = topic.summary.trimmingCharacters(in: .whitespacesAndNewlines)
            if !summary.isEmpty { parts.append("summary: " + summary) }
            if topic.status == .unsupported {
                parts.append("status: NOT SUPPORTED in kindaVim")
            }
            if let section = topic.sections.first(where: {
                !$0.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }) {
                let body = section.body.trimmingCharacters(in: .whitespacesAndNewlines)
                parts.append("")
                parts.append(body)
            }
        }
        if let qa {
            parts.append("")
            parts.append("Closest canonical Q&A:")
            parts.append("Q: \(qa.question)")
            parts.append("A: \(qa.answer)")
        }
        parts.append("---")
        return parts.joined(separator: "\n")
    }

    /// Snapshot of prior user/assistant turns for OpenAI. Skips the
    /// latest user message (it's sent separately as `userQuery`) and
    /// pulls only recent turns so long sessions don't inflate token
    /// usage. Caps at 6 prior messages — enough for natural
    /// follow-ups, small enough to not dominate the context window.
    private func priorOpenAIHistory() -> [OpenAIBackend.HistoryMessage] {
        let maxTurns = 6
        // `messages` already contains the newest user turn (appended
        // in send()) — drop it so it isn't duplicated in the API call.
        let prior = messages.dropLast()
        let recent = prior.suffix(maxTurns)
        return recent.compactMap { msg in
            let content = msg.plainText
            guard !content.isEmpty else { return nil }
            switch msg.role {
            case .user:      return .init(role: "user", content: content)
            case .assistant: return .init(role: "assistant", content: content)
            case .system:    return nil
            }
        }
    }

    /// Resolve related lessons from a topic's authored `lessons:`
    /// metadata. This is authoritative — each topic file lists the
    /// curriculum lessons that teach it. Avoids the false positives
    /// from keyword-overlap matching on answer prose.
    private static func resolveRelatedLessons(
        from topic: HelpTopic, chapters: [Chapter]
    ) -> [ChatMessage.RelatedLessonRef] {
        topic.lessonIDs.prefix(3).compactMap { lessonID in
            guard let chapter = chapters.first(where: {
                $0.lessons.contains(where: { $0.id == lessonID })
            }),
            let lesson = chapter.lessons.first(where: { $0.id == lessonID })
            else { return nil }
            return ChatMessage.RelatedLessonRef(
                id: lessonID,
                title: lesson.title,
                chapterNumber: chapter.number,
                lessonNumber: lesson.number
            )
        }
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
        // Use the topic's own `lessons:` metadata (human-authored)
        // rather than keyword-overlap on the answer prose, which
        // produced false positives like "Delete Entire Line" for a
        // paragraph-jump answer that happened to contain "blank line".
        bubble.relatedLessons = Self.resolveRelatedLessons(
            from: topic, chapters: chapters
        )
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
        // Build per-command summaries from the support corpus so
        // Related rows read like "0 — move to first column of line"
        // rather than the repeated topic title ("Line Motions").
        // Fall back to the topic title only when the corpus has no
        // note for that command.
        let corpus = KindaVimSupportCorpus.shared
        let related = topic.tags
            .filter { !$0.isEmpty && $0 != topic.id }
            .prefix(4)
            .map { tag in
                let note = corpus.note(for: tag)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let summary = (note?.isEmpty == false) ? note! : topic.title
                return VimAnswerDisplay.RelatedCommandDisplay(
                    command: tag,
                    summary: summary
                )
            }

        var display = VimAnswerDisplay(
            answer: Self.topicReferenceBody(for: topic),
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
        bubble.relatedLessons = Self.resolveRelatedLessons(
            from: topic, chapters: chapters
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

    /// OpenAI path — streams gpt-5.4 through OpenAIBackend. Uses the
    /// same system prompt the Apple path uses so instruction-tuning
    /// carries over, plus an optional "Reference for this question"
    /// block built from the matched canonical topic so the model
    /// grounds its answer in our authored content. Renders into the
    /// same VimAnswerDisplay bubble so related-commands /
    /// related-lessons post-processing still runs.
    private func streamOpenAIReply(
        to userText: String,
        apiKey: String,
        referenceTopic: HelpTopic? = nil,
        referenceTopics: [HelpTopic] = [],
        referenceQA: CanonicalQA? = nil
    ) async {
        isResponding = true
        defer { isResponding = false }

        // Snapshot prior turns BEFORE appending the assistant bubble
        // so history sent to OpenAI doesn't include the empty bubble
        // we're about to render into.
        let history = priorOpenAIHistory()

        var bubble = ChatMessage(
            role: .assistant,
            payload: .answer(VimAnswerDisplay()),
            isStreaming: true
        )
        // Surface the topic the answer is grounded in so the "From
        // reference" badge still shows for OpenAI-served answers.
        if let topic = referenceTopic {
            bubble.canonicalSource = ChatMessage.CanonicalSource(
                topicID: topic.id,
                topicTitle: topic.title
            )
            bubble.relatedLessons = Self.resolveRelatedLessons(
                from: topic, chapters: chapters
            )
        }
        messages.append(bubble)
        let index = messages.count - 1

        let prompt = systemInstructions(forBackend: .openAI)
            + Self.referenceBlock(
                topics: referenceTopics,
                qa: referenceQA
            )
        do {
            var finalSnapshot: OpenAIBackend.Snapshot?
            let stream = OpenAIBackend.stream(
                userQuery: userText,
                systemPrompt: prompt,
                apiKey: apiKey,
                history: history
            )
            for try await snap in stream {
                finalSnapshot = snap
                bubble.payload = .answer(
                    VimAnswerDisplay(
                        answer: snap.answer,
                        relatedCommands: snap.relatedCommands,
                        fasterAlternative: snap.fasterAlternative,
                        webSearchQuery: snap.webSearchQuery,
                        videoSearchQuery: snap.videoSearchQuery,
                        isUnsupported: snap.isUnsupported,
                        terminalVimExplanation: snap.terminalVimExplanation
                    )
                )
                messages[index] = bubble
            }

            bubble.isStreaming = false
            if let final = finalSnapshot {
                let resolvedUnsupported = Self.resolveUnsupported(
                    modelFlag: final.isUnsupported,
                    userQuery: userText,
                    answer: final.answer
                )
                let display = VimAnswerDisplay(
                    answer: final.answer,
                    relatedCommands: final.relatedCommands,
                    fasterAlternative: final.fasterAlternative,
                    webSearchQuery: final.webSearchQuery,
                    videoSearchQuery: final.videoSearchQuery,
                    isUnsupported: resolvedUnsupported,
                    terminalVimExplanation: resolvedUnsupported
                        ? final.terminalVimExplanation : nil
                )
                bubble.payload = .answer(display)
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

                await fetchSupplementaryResultsForCanonical(
                    webQuery: final.webSearchQuery,
                    videoQuery: final.videoSearchQuery,
                    messageIndex: index
                )
            } else {
                messages[index] = bubble
            }
        } catch {
            AppLogger.shared.error("chat", "openAIStreamFailed", fields: [
                "query": userText,
                "error": String(describing: error),
            ])
            bubble.payload = .text(
                (error as? LocalizedError)?.errorDescription
                ?? "OpenAI request failed. Check the console log for details."
            )
            bubble.isStreaming = false
            messages[index] = bubble
        }
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
        let rawAnswer = partial.answer ?? ""
        // Flag answers that recommend macOS shortcuts as the
        // primary answer — the model sometimes defaults to
        // `PgUp` / `PgDn` / `Home` / `End` / arrow keys when the
        // question is ambiguous. Those aren't Vim motions and
        // shouldn't be the headline reply.
        if Self.answersWithMacOSOnlyKeys(rawAnswer) {
            AppLogger.shared.warn("chat", "macOSFallbackDetected", fields: [
                "query": userQuery,
                "answer": String(rawAnswer.prefix(200))
            ])
        }
        let modelSaysUnsupported = partial.isUnsupported ?? false
        let resolvedUnsupported = Self.resolveUnsupported(
            modelFlag: modelSaysUnsupported,
            userQuery: userQuery,
            answer: rawAnswer
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

    /// Composes a more substantive topic-reference answer than the
    /// one-line `topic.summary` we used to emit. Uses the first
    /// prose section of the topic as the main body (usually a 2–4
    /// sentence explanation we authored), prepends the summary as a
    /// brief lede, and appends a pointer to the Manual. Falls back
    /// to summary alone when the topic has no prose sections.
    private static func topicReferenceBody(for topic: HelpTopic) -> String {
        let summary = topic.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let firstSection = topic.sections.first(where: {
            !$0.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) else {
            return summary.isEmpty
                ? "Open the Manual entry for the full reference."
                : summary + " Open the Manual entry for the full reference."
        }
        let body = firstSection.body.trimmingCharacters(in: .whitespacesAndNewlines)
        var parts: [String] = []
        if !summary.isEmpty { parts.append(summary) }
        parts.append(body)
        parts.append("Open the Manual entry for the full reference.")
        return parts.joined(separator: "\n\n")
    }

    /// Log-only signal that the model recommended a macOS-only
    /// shortcut (PgUp/Home/End/Cmd+F/arrow keys) as the primary
    /// answer, where a Vim motion would be correct. The answer
    /// still renders — we don't have a safe auto-rewrite — but
    /// the app log captures the regression so prompt-tuning can
    /// improve over time.
    private static func answersWithMacOSOnlyKeys(_ answer: String) -> Bool {
        // Match the key token inside backticks, so prose mentions
        // of "PgUp" don't trigger. Look for the suspect keys as
        // the ONLY command-looking thing in a short answer.
        let macOnly = ["PgUp", "PgDn", "Home", "End",
                       "Up", "Down", "Left", "Right",
                       "Cmd+F", "Cmd+G"]
        guard let range = answer.range(of: "^\\s*(Press|Type)\\s+`([^`]+)`",
                                       options: .regularExpression),
              let cmdRange = answer[range].range(of: "`([^`]+)`",
                                                 options: .regularExpression) else {
            return false
        }
        let cmd = answer[cmdRange].trimmingCharacters(in: CharacterSet(charactersIn: "`"))
        return macOnly.contains(cmd)
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

    private func systemInstructions(forBackend backend: AIBackend = .apple) -> String {
        // The Apple on-device 3B model drifts (suggests macOS
        // shortcuts, mislabels supported commands) so it needs
        // heavier guardrails + the full unsupported corpus inlined.
        // OpenAI is tightly grounded by the per-query `referenceBlock`
        // appended separately and doesn't need either.
        let heavyGuards = backend == .apple
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
        - For unsupported commands, set `isUnsupported` to true, keep `answer` short and definitive, and put any stock-Vim explanation in `terminalVimExplanation`.


        """
        if heavyGuards {
            prompt.append("""
            ## Vim-only answers
            Every answer MUST be a Vim motion, operator, or text object.
            NEVER recommend macOS keyboard shortcuts as the primary answer —
            `PgUp`, `PgDn`, `Home`, `End`, arrow keys, `Cmd+F`, etc. are NOT
            acceptable. The user already knows about those; they want the
            Vim way. Examples of correct reframing:
            - "how do I jump to the next paragraph?" → `}` (NOT `PgDn`).
            - "how do I go to the end of the file?" → `G` (NOT `Cmd+Down`).
            - "how do I search?" → `/` (NOT `Cmd+F`).
            macOS shortcuts MAY appear in unsupported-feature answers when
            kindaVim legitimately doesn't implement a Vim equivalent
            (e.g. named registers → `Cmd+C`/`Cmd+V`). Never otherwise.

            \(KindaVimSupportCorpus.asPromptBlock())


            """)
        }
        prompt.append("""
        ## Supplementary search
        Populate `webSearchQuery` only when external tutorials would help.
        Leave it null for self-contained single-command answers.
        Include the word "tutorial" when a video walkthrough would help.

        """)
        if let lesson = currentLesson, let chapter = currentChapterTitle {
            prompt.append("""

            ## Current lesson context
            The user is on chapter "\(chapter)", lesson "\(lesson.title)".

            """)
        }
        // Apple path needs the viewed-topic block inlined so it has
        // something to ground on. OpenAI gets the matched topics via
        // `referenceBlock` appended by the caller and doesn't need
        // the viewed-topic duplication.
        if heavyGuards {
            prompt.append("\n## kindaVim manual\n\n")
            prompt.append(Self.helpCorpusBlock(currentTopicID: currentHelpTopicID))
        }
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
