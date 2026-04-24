import Testing
@testable import KindaVimTutor

@Suite("Help corpus integrity")
struct HelpCorpusTests {
    @Test("sample help topics load from the bundled corpus")
    func loadsSampleTopics() {
        let topics = KindaVimHelpCorpus.shared.topics
        let ids = Set(topics.map(\.id))

        #expect(ids.contains("dedication"))
        #expect(ids.contains("delete-word"))
        #expect(ids.contains("find-character"))
        #expect(ids.contains("macros"))
    }

    @Test("delete-word topic parses structured metadata and canonical QA")
    func deleteWordTopicStructure() throws {
        let topic = try #require(KindaVimHelpCorpus.shared.topic(id: "delete-word"))

        #expect(topic.title == "Delete Word")
        #expect(topic.status == .supported)
        #expect(topic.tags == ["dw", "d2w", "delete-word"])
        #expect(topic.aliases == ["delete word", "delete next word", "operator plus motion"])
        #expect(topic.lessonIDs == ["ch2.l1", "ch2.l4", "ch2.l6"])
        #expect(topic.relatedTopicIDs == ["find-character"])
        #expect(topic.suggestedQuestions.count == 3)
        #expect(topic.sections.map(\.title) == [
            "What It Does",
            "How To Use It In KindaVim",
            "Difference From Stock Vim"
        ])

        #expect(topic.canonicalQA.count == 9)
        let firstQA = try #require(topic.canonicalQA.first)
        #expect(firstQA.question == "How do I delete a word?")
        #expect(firstQA.answer.contains("`dw`"))
        #expect(firstQA.relatedCommands.count == 2)
        #expect(firstQA.relatedCommands.map(\.command) == ["diw", "daw"])
        #expect(firstQA.fasterAlternative?.contains("`D`") == true)
    }

    @Test("topic lookup works by command, alias, and lesson id")
    func topicLookup() throws {
        let corpus = KindaVimHelpCorpus.shared

        #expect(corpus.topic(forCommand: "dw")?.id == "delete-word")
        #expect(corpus.topic(forCommand: "delete word")?.id == "delete-word")
        #expect(corpus.topic(forCommand: "f")?.id == "find-character")
        #expect(corpus.topic(forCommand: "q")?.id == "macros")
        #expect(corpus.topic(forCommand: "recording")?.id == "macros")
        #expect(corpus.topic(forQuery: #"Explain `ci"`"#)?.id == "change-operator")
        #expect(corpus.topic(forQuery: #"Explain `di"`"#)?.id == "text-objects")
        #expect(corpus.topic(forQuery: "Explain `inside word`")?.id == "text-objects")
        #expect(corpus.topic(forQuery: "How do I change inside “quotes”?")?.id == "change-operator")
        #expect(corpus.topic(forLessonID: "ch2.l1")?.id == "delete-word")
        #expect(corpus.topic(forLessonID: "ch4.l2")?.id == "find-character")
        #expect(corpus.topic(forCommand: "not-a-command") == nil)

        let dedication = try #require(corpus.topic(id: "dedication"))
        #expect(dedication.canonicalQA.isEmpty)
        #expect(dedication.lessonIDs.isEmpty)
    }

    @Test("unsupported macros topic parses canonical unsupported answers")
    func macrosTopicStructure() throws {
        let topic = try #require(KindaVimHelpCorpus.shared.topic(id: "macros"))

        #expect(topic.status == .unsupported)
        #expect(topic.tags.contains("q"))
        #expect(topic.aliases == ["recording", "replay"])
        #expect(topic.canonicalQA.count == 5)

        let firstQA = try #require(topic.canonicalQA.first)
        #expect(firstQA.isUnsupported)
        #expect(firstQA.answer.contains("doesn't support macros"))
        #expect(firstQA.terminalVimExplanation?.contains("`q`") == true)
        #expect(firstQA.relatedCommands.map(\.command) == ["."])
    }

    @Test("all related topic ids resolve")
    func relatedTopicIDsResolve() {
        let corpus = KindaVimHelpCorpus.shared

        for topic in corpus.topics {
            for relatedID in topic.relatedTopicIDs {
                #expect(
                    corpus.topic(id: relatedID) != nil,
                    "\(topic.id) references missing related topic \(relatedID)"
                )
            }
        }
    }
}
