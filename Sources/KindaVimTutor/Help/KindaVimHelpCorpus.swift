import Foundation

enum KindaVimHelpCorpus {
    static let shared = load()

    struct Corpus: Sendable {
        let topics: [HelpTopic]
        let topicsByID: [String: HelpTopic]
        let topicIDByLessonID: [String: String]

        func topic(id: String?) -> HelpTopic? {
            guard let id else { return nil }
            return topicsByID[id]
        }

        func topic(forLessonID lessonID: String) -> HelpTopic? {
            guard let topicID = topicIDByLessonID[lessonID] else { return nil }
            return topicsByID[topicID]
        }

        /// Finds the topic that most canonically covers the given
        /// command string (e.g. "dw", "ciw"). Used by the manual's
        /// clickable tag / alias / command chips so the user can
        /// jump between related entries.
        func topic(forCommand command: String) -> HelpTopic? {
            topic(forQuery: command)
        }

        /// Broader deterministic lookup used by chat and manual.
        /// Handles exact commands, aliases, smart quotes, and
        /// operator+text-object phrases like "change inside word".
        func topic(forQuery query: String, preferredTopicID: String? = nil) -> HelpTopic? {
            let candidates = HelpQueryNormalizer.normalizedLookupCandidates(for: query)
            guard !candidates.isEmpty else { return nil }

            var bestTopic: HelpTopic?
            var bestScore = Int.min

            for topic in topics {
                let score = score(topic: topic, for: candidates, preferredTopicID: preferredTopicID)
                if score > bestScore {
                    bestScore = score
                    bestTopic = topic
                }
            }

            guard bestScore >= 60 else { return nil }
            return bestTopic
        }

        /// Return the top-scoring topics for a query, above the same
        /// relevance floor used by `topic(forQuery:)`. Useful when the
        /// caller can afford to ground an LLM in 2-3 nearby references
        /// rather than just the single best match.
        func topics(
            forQuery query: String,
            limit: Int,
            preferredTopicID: String? = nil
        ) -> [HelpTopic] {
            let candidates = HelpQueryNormalizer.normalizedLookupCandidates(for: query)
            guard !candidates.isEmpty else { return [] }
            let scored: [(HelpTopic, Int)] = topics.map { topic in
                (topic, score(topic: topic, for: candidates,
                              preferredTopicID: preferredTopicID))
            }
            return scored
                .filter { $0.1 >= 60 }
                .sorted { $0.1 > $1.1 }
                .prefix(limit)
                .map(\.0)
        }

        private func score(
            topic: HelpTopic,
            for candidates: [String],
            preferredTopicID: String?
        ) -> Int {
            let normalizedTags = Set(topic.tags.map(HelpQueryNormalizer.normalizedComparable))
            let normalizedAliases = Set(topic.aliases.map(HelpQueryNormalizer.normalizedComparable))
            let normalizedTitle = HelpQueryNormalizer.normalizedComparable(topic.title)
            let normalizedID = HelpQueryNormalizer.normalizedComparable(topic.id)
            let canonicalQuestionText = topic.canonicalQA
                .map(\.question)
                .map(HelpQueryNormalizer.normalizedComparable)
                .joined(separator: "\n")
            let canonicalAnswerText = topic.canonicalQA
                .map(\.answer)
                .map(HelpQueryNormalizer.normalizedComparable)
                .joined(separator: "\n")
            let canonicalRelatedCommands = Set(
                topic.canonicalQA
                    .flatMap(\.relatedCommands)
                    .map(\.command)
                    .map(HelpQueryNormalizer.normalizedComparable)
            )

            var score = 0
            for candidate in candidates {
                if normalizedTags.contains(candidate) {
                    score = max(score, 100)
                }
                if normalizedAliases.contains(candidate) {
                    score = max(score, 95)
                }
                if normalizedTitle == candidate || normalizedID == candidate {
                    score = max(score, 90)
                }
                if canonicalRelatedCommands.contains(candidate)
                    || canonicalQuestionText.contains(candidate)
                    || canonicalAnswerText.contains(candidate)
                {
                    score = max(score, 83)
                }

                if let decomposition = HelpQueryNormalizer.decomposeCommandToken(candidate) {
                    if normalizedTags.contains(decomposition.core) {
                        score = max(score, decomposition.operatorPrefix == nil ? 88 : 84)
                    }
                    if normalizedAliases.contains(decomposition.core) {
                        score = max(score, 82)
                    }
                    if canonicalRelatedCommands.contains(decomposition.core)
                        || canonicalQuestionText.contains(decomposition.core)
                        || canonicalAnswerText.contains(decomposition.core)
                    {
                        var canonicalScore = 83
                        if let op = decomposition.operatorPrefix,
                           normalizedTags.contains(op) {
                            canonicalScore += 5
                        }
                        score = max(score, canonicalScore)
                    }
                }
            }

            if topic.id == preferredTopicID, score > 0 {
                score += 2
            }
            return score
        }
    }

    static var topics: [HelpTopic] { shared.topics }

    static func topic(id: String?) -> HelpTopic? {
        shared.topic(id: id)
    }

    static func topic(forLessonID lessonID: String) -> HelpTopic? {
        shared.topic(forLessonID: lessonID)
    }

    static func topics(
        forQuery query: String,
        limit: Int,
        preferredTopicID: String? = nil
    ) -> [HelpTopic] {
        shared.topics(forQuery: query, limit: limit, preferredTopicID: preferredTopicID)
    }

    static func topic(forQuery query: String, preferredTopicID: String? = nil) -> HelpTopic? {
        shared.topic(forQuery: query, preferredTopicID: preferredTopicID)
    }

    private static func load() -> Corpus {
        let urls = resourceURLs()
        let parsedTopics = urls
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap(parse(url:))
        var seenTopicIDs: Set<String> = []
        let topics = parsedTopics.filter { seenTopicIDs.insert($0.id).inserted }
        let topicsByID = Dictionary(uniqueKeysWithValues: topics.map { ($0.id, $0) })

        var topicIDByLessonID: [String: String] = [:]
        for topic in topics {
            for lessonID in topic.lessonIDs {
                topicIDByLessonID[lessonID] = topic.id
            }
        }
        return Corpus(
            topics: topics,
            topicsByID: topicsByID,
            topicIDByLessonID: topicIDByLessonID
        )
    }

    private static func resourceURLs() -> [URL] {
        let fm = FileManager.default
        var urls: [URL] = []

        if let bundleScoped = Bundle.module.urls(
            forResourcesWithExtension: "txt",
            subdirectory: "kindavim-help"
        ) {
            urls.append(contentsOf: bundleScoped)
        }

        // SwiftPM resource packaging can flatten files into the bundle
        // root in app builds. Scan the full bundle root instead of
        // hard-coding a few sample files so new help topics are
        // automatically visible in tests and local debug builds.
        if let moduleRoot = Bundle.module.resourceURL,
           let rootURLs = try? fm.contentsOfDirectory(
                at: moduleRoot,
                includingPropertiesForKeys: nil
           ) {
            urls.append(contentsOf: rootURLs.filter { $0.pathExtension == "txt" })
        }

        // The packaged app also copies raw Resources/ into
        // Contents/Resources/kindavim-help. Prefer this as a final
        // fallback so the manual still works if SwiftPM bundle lookup
        // changes shape.
        if let appResources = Bundle.main.resourceURL?
            .appendingPathComponent("kindavim-help", isDirectory: true),
           let diskURLs = try? fm.contentsOfDirectory(
                at: appResources,
                includingPropertiesForKeys: nil
           ) {
            urls.append(contentsOf: diskURLs.filter { $0.pathExtension == "txt" })
        }

        var seen: Set<String> = []
        return urls.filter { seen.insert($0.standardizedFileURL.path).inserted }
    }

    private static func parse(url: URL) -> HelpTopic? {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }
        let lines = text.components(separatedBy: .newlines)
        var metadata: [String: String] = [:]
        var bodyLines: [String] = []
        var readingBody = false

        for line in lines {
            if !readingBody {
                if line.trimmingCharacters(in: .whitespaces).isEmpty {
                    readingBody = true
                    continue
                }
                let parts = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
                guard parts.count == 2 else { continue }
                metadata[String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()] =
                    String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                bodyLines.append(line)
            }
        }

        guard let id = metadata["id"],
              let title = metadata["title"],
              let summary = metadata["summary"],
              let statusRaw = metadata["status"],
              let status = HelpTopicStatus(rawValue: statusRaw.lowercased()) else {
            return nil
        }

        let allSections = parseSections(bodyLines.joined(separator: "\n"))
        // Split out the "Canonical QA" section into structured Q&A
        // entries and remove it from the displayed prose sections.
        let qaSection = allSections.first(where: {
            $0.title.lowercased().hasPrefix("canonical qa")
        })
        let proseSections = allSections.filter {
            !$0.title.lowercased().hasPrefix("canonical qa")
        }

        return HelpTopic(
            id: id,
            title: title,
            summary: summary,
            tags: csv(metadata["tags"]),
            aliases: csv(metadata["aliases"]),
            status: status,
            lessonIDs: csv(metadata["lessons"]),
            relatedTopicIDs: csv(metadata["related"]),
            suggestedQuestions: pipeList(metadata["questions"]),
            webSearchQuery: metadata["web"],
            videoSearchQuery: metadata["video"],
            sections: proseSections,
            canonicalQA: qaSection.map(parseCanonicalQA) ?? []
        )
    }

    /// Parses a `## Canonical QA` section's body into structured
    /// `CanonicalQA` entries. Format (one entry per Q: line):
    ///
    ///     Q: How do I delete a word?
    ///     A: Type `dw` in {{normal}} …
    ///     Related: diw — delete inside word; daw — delete around word
    ///     Faster: Press `D` to delete to end of line.
    ///
    /// `A:` body is taken from the line after `A:` through the first
    /// subsequent known key (`Related:`, `Faster:`, or next `Q:`).
    private static func parseCanonicalQA(_ section: HelpTopicSection) -> [CanonicalQA] {
        let lines = section.body.components(separatedBy: .newlines)
        var out: [CanonicalQA] = []
        var currentQuestion: String?
        var currentAnswer: [String] = []
        var currentRelated: String?
        var currentFaster: String?
        var currentUnsupported: Bool = false
        var currentTerminalVim: String?
        var activeKey: String = "A"

        func flush() {
            guard let q = currentQuestion,
                  !currentAnswer.isEmpty else {
                currentQuestion = nil
                currentAnswer = []
                currentRelated = nil
                currentFaster = nil
                currentUnsupported = false
                currentTerminalVim = nil
                return
            }
            out.append(CanonicalQA(
                question: q.trimmingCharacters(in: .whitespacesAndNewlines),
                answer: currentAnswer.joined(separator: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                relatedCommands: parseRelated(currentRelated),
                fasterAlternative: currentFaster?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .nonEmpty,
                isUnsupported: currentUnsupported,
                terminalVimExplanation: currentTerminalVim?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .nonEmpty
            ))
            currentQuestion = nil
            currentAnswer = []
            currentRelated = nil
            currentFaster = nil
            currentUnsupported = false
            currentTerminalVim = nil
        }

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.hasPrefix("Q:") {
                flush()
                currentQuestion = String(line.dropFirst(2))
                activeKey = "Q"
            } else if line.hasPrefix("A:") {
                currentAnswer = [String(line.dropFirst(2))
                    .trimmingCharacters(in: .whitespaces)]
                activeKey = "A"
            } else if line.lowercased().hasPrefix("related:") {
                currentRelated = String(line.dropFirst(8))
                    .trimmingCharacters(in: .whitespaces)
                activeKey = "Related"
            } else if line.lowercased().hasPrefix("faster:") {
                currentFaster = String(line.dropFirst(7))
                    .trimmingCharacters(in: .whitespaces)
                activeKey = "Faster"
            } else if line.lowercased().hasPrefix("unsupported:") {
                let raw = line.dropFirst("unsupported:".count)
                    .trimmingCharacters(in: .whitespaces)
                    .lowercased()
                currentUnsupported = (raw == "yes" || raw == "true")
                activeKey = "Unsupported"
            } else if line.lowercased().hasPrefix("terminalvim:") {
                currentTerminalVim = String(line.dropFirst("terminalvim:".count))
                    .trimmingCharacters(in: .whitespaces)
                activeKey = "TerminalVim"
            } else if !line.isEmpty {
                // Continuation line — append to whichever field is
                // currently being accumulated (usually A: or TerminalVim).
                switch activeKey {
                case "A":            currentAnswer.append(line)
                case "Related":      currentRelated = (currentRelated ?? "") + " " + line
                case "Faster":       currentFaster = (currentFaster ?? "") + " " + line
                case "TerminalVim":  currentTerminalVim = (currentTerminalVim ?? "") + " " + line
                default:             break
                }
            }
        }
        flush()
        return out
    }

    /// Splits a "Related:" value on `;` separators, each entry in
    /// `command — summary` (em-dash) or `command: summary` form.
    private static func parseRelated(_ raw: String?) -> [CanonicalQA.RelatedCommandEntry] {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else { return [] }
        return raw.split(separator: ";").compactMap { chunk in
            let parts = chunk.split(
                whereSeparator: { $0 == "—" || $0 == "-" || $0 == ":" }
            )
            guard parts.count >= 2 else { return nil }
            let command = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let summary = parts[1...].joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !command.isEmpty else { return nil }
            return .init(command: command, summary: summary)
        }
    }

    private static func csv(_ value: String?) -> [String] {
        guard let value else { return [] }
        return value
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Canonical-QA helpers
}

private extension String {
    /// Returns nil when the trimmed string is empty. Used to
    /// normalise optional canonical-QA fields that came back blank.
    var nonEmpty: String? {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

extension KindaVimHelpCorpus {
    fileprivate static func pipeList(_ value: String?) -> [String] {
        guard let value else { return [] }
        return value
            .components(separatedBy: "||")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func parseSections(_ body: String) -> [HelpTopicSection] {
        var sections: [HelpTopicSection] = []
        var currentTitle: String?
        var currentBody: [String] = []

        for line in body.components(separatedBy: .newlines) {
            if line.hasPrefix("## ") {
                if let currentTitle {
                    sections.append(.init(
                        title: currentTitle,
                        body: currentBody.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                    ))
                }
                currentTitle = String(line.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
                currentBody = []
            } else {
                currentBody.append(line)
            }
        }

        if let currentTitle {
            sections.append(.init(
                title: currentTitle,
                body: currentBody.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            ))
        }

        return sections.filter { !$0.body.isEmpty }
    }
}
