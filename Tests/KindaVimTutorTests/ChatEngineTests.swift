import Testing
@testable import KindaVimTutor

@MainActor
@Suite("ChatEngine canonical help flow", .serialized)
struct ChatEngineTests {
    @Test("activate seeds the greeting once")
    func activateSeedsGreetingOnce() {
        let engine = ChatEngine()

        engine.activate(
            lesson: nil,
            chapterTitle: nil,
            chapters: Curriculum.chapters,
            helpTopicID: nil
        )
        #expect(engine.messages.count == 1)
        #expect(engine.messages.first?.role == .assistant)
        #expect(engine.messages.first?.plainText == "What Vim questions do you have?")

        engine.activate(
            lesson: nil,
            chapterTitle: nil,
            chapters: Curriculum.chapters,
            helpTopicID: "delete-word"
        )
        #expect(engine.messages.count == 1)
    }

    @Test("sending an exact canonical question appends a canonical answer bubble")
    func sendCanonicalQuestion() throws {
        let engine = ChatEngine()
        engine.activate(
            lesson: nil,
            chapterTitle: nil,
            chapters: Curriculum.chapters,
            helpTopicID: "delete-word"
        )

        engine.input = "How do I delete a word?"
        engine.send()

        #expect(engine.input.isEmpty)
        #expect(engine.messages.count == 3)

        let user = engine.messages[1]
        #expect(user.role == .user)
        #expect(user.plainText == "How do I delete a word?")

        let assistant = engine.messages[2]
        #expect(assistant.role == .assistant)
        let source = try #require(assistant.canonicalSource)
        #expect(source.topicID == "delete-word")
        #expect(source.topicTitle == "Delete Word")

        guard case .answer(let display) = assistant.payload else {
            Issue.record("Expected a structured canonical answer payload")
            return
        }

        #expect(display.isCanonical)
        #expect(display.answer.contains("`dw`"))
        #expect(display.relatedCommands.map(\.command) == ["diw", "daw"])
        #expect(display.fasterAlternative?.contains("`D`") == true)
        #expect(display.webSearchQuery == nil)
        #expect(display.videoSearchQuery == nil)
    }

    @Test("topic preference steers ambiguous canonical lookup toward the active help topic")
    func topicPreferenceSteersCanonicalLookup() throws {
        let engine = ChatEngine()
        engine.activate(
            lesson: nil,
            chapterTitle: nil,
            chapters: Curriculum.chapters,
            helpTopicID: "delete-word"
        )

        engine.input = "What's the difference between dw and de?"
        engine.send()

        let assistant = try #require(engine.messages.last)
        let source = try #require(assistant.canonicalSource)
        #expect(source.topicID == "delete-word")
    }

    @Test("unsupported canonical answers preserve the split between kindaVim and terminal Vim")
    func sendUnsupportedCanonicalQuestion() throws {
        let engine = ChatEngine()
        engine.activate(
            lesson: nil,
            chapterTitle: nil,
            chapters: Curriculum.chapters,
            helpTopicID: "macros"
        )

        engine.input = "How do I record a macro in kindaVim?"
        engine.send()

        let assistant = try #require(engine.messages.last)
        let source = try #require(assistant.canonicalSource)
        #expect(source.topicID == "macros")

        guard case .answer(let display) = assistant.payload else {
            Issue.record("Expected a structured canonical answer payload")
            return
        }

        #expect(display.isCanonical)
        #expect(display.isUnsupported)
        #expect(display.answer.contains("doesn't support macros"))
        #expect(display.terminalVimExplanation?.contains("`q`") == true)
        #expect(display.relatedCommands.map(\.command) == ["."])
    }

    @Test("topic lookup fallback answers documented commands without using the model")
    func sendTopicFallbackQuestion() throws {
        let engine = ChatEngine()
        engine.activate(
            lesson: nil,
            chapterTitle: nil,
            chapters: Curriculum.chapters,
            helpTopicID: nil
        )

        engine.input = "Explain `inside word`"
        engine.send()

        let assistant = try #require(engine.messages.last)
        let source = try #require(assistant.canonicalSource)
        #expect(source.topicID == "text-objects")

        guard case .answer(let display) = assistant.payload else {
            Issue.record("Expected a structured topic-reference answer payload")
            return
        }

        #expect(display.isCanonical)
        #expect(display.answer.contains("Text objects"))
    }

    @Test("topic lookup normalizes smart quotes and operator-plus-object phrases")
    func sendNormalizedTopicQuestion() throws {
        let engine = ChatEngine()
        engine.activate(
            lesson: nil,
            chapterTitle: nil,
            chapters: Curriculum.chapters,
            helpTopicID: nil
        )

        engine.input = "How do I change inside “quotes”?"
        engine.send()

        let assistant = try #require(engine.messages.last)
        let source = try #require(assistant.canonicalSource)
        #expect(source.topicID == "change-operator")
    }

    @Test("system prompt stays under the on-device model budget")
    func systemPromptStaysWithinBudget() {
        let engine = ChatEngine()
        engine.activate(
            lesson: Curriculum.chapters[0].lessons.first,
            chapterTitle: Curriculum.chapters[0].title,
            chapters: Curriculum.chapters,
            helpTopicID: "delete-word"
        )

        let snapshot = engine.debugPromptSnapshot()

        #expect(snapshot.text.contains("Delete Word"))
        #expect(snapshot.estimatedTokenCount <= 3400)
    }

    /// Worst-case prompt size guard. The biggest help topic becomes
    /// the "currently viewed" topic (so its full body gets embedded
    /// in the system prompt), with a lesson context attached. If any
    /// corpus edit pushes the prompt past the budget, this test
    /// fails before the runtime hits the 3B on-device model's
    /// 4096-token context-window error.
    @Test("worst-case system prompt stays under the on-device model budget")
    func worstCaseSystemPromptStaysWithinBudget() throws {
        // Budget: 4096 total context window, minus ~700 tokens
        // reserved for the user's question + prior turn history +
        // structured VimAnswer output. 3400 is what the current
        // engine keeps on a typical topic; we hold worst-case to
        // the same cap so corpus growth is surfaced immediately.
        let tokenBudget = 3400

        // Pick the topic whose full-serialization is largest. If
        // someone adds a huge new topic, this selects it
        // automatically — no need to update the test.
        let topics = KindaVimHelpCorpus.topics
        let biggestTopic = try #require(
            topics.max(by: { lhs, rhs in
                bodyLength(of: lhs) < bodyLength(of: rhs)
            })
        )

        let engine = ChatEngine()
        engine.activate(
            lesson: Curriculum.chapters[0].lessons.first,
            chapterTitle: Curriculum.chapters[0].title,
            chapters: Curriculum.chapters,
            helpTopicID: biggestTopic.id
        )

        let snapshot = engine.debugPromptSnapshot()

        // Diagnostic for the failure path — shows which topic
        // triggered the overrun and how far over we are.
        if snapshot.estimatedTokenCount > tokenBudget {
            Issue.record(
                """
                System prompt exceeded budget.
                Budget: \(tokenBudget) tokens. Estimated: \(snapshot.estimatedTokenCount).
                Worst-case topic: \(biggestTopic.id) (\(biggestTopic.title)).
                Check docs/llm-api-efficiency.md and trim kindavim-support.txt /
                the biggest topic body before shipping.
                """
            )
        }
        #expect(snapshot.estimatedTokenCount <= tokenBudget)
    }

    @Test("referenceBlock injects matched topic bodies for OpenAI grounding")
    func referenceBlockGroundsOnMatchedTopics() throws {
        // Pick a topic we know has a prose section so we can check
        // its body lands in the block. Delete Word is a safe, stable
        // pick — it's part of the core curriculum.
        let topics = KindaVimHelpCorpus.topics
        let deleteWord = try #require(topics.first(where: { $0.id == "delete-word" }))

        let block = ChatEngine.referenceBlock(topics: [deleteWord], qa: nil)

        #expect(block.contains("Reference for this question"))
        #expect(block.contains("### \(deleteWord.title)"))
        #expect(block.contains("commands: " + deleteWord.tags.joined(separator: ", ")))
        // At least some of the first prose section should appear.
        let firstBody = deleteWord.sections.first(where: {
            !$0.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        })?.body.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        #expect(!firstBody.isEmpty)
        #expect(block.contains(String(firstBody.prefix(40))))

        // Empty inputs produce empty block — safe to concatenate.
        #expect(ChatEngine.referenceBlock(topics: [], qa: nil).isEmpty)
    }

    private func bodyLength(of topic: HelpTopic) -> Int {
        let sections = topic.sections.reduce(0) { acc, s in
            acc + s.title.count + s.body.count
        }
        return topic.title.count + topic.summary.count + sections
            + topic.tags.joined().count + topic.aliases.joined().count
    }
}
