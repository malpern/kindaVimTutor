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
}
