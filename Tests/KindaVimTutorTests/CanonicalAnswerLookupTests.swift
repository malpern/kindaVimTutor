import Testing
@testable import KindaVimTutor

@Suite("Canonical answer lookup")
struct CanonicalAnswerLookupTests {
    @Test("exact canonical question matches the authored delete-word answer")
    func exactMatch() throws {
        let match = try #require(
            CanonicalAnswerLookup.match(
                for: "How do I delete a word?",
                in: KindaVimHelpCorpus.topics
            )
        )

        #expect(match.topic.id == "delete-word")
        #expect(match.qa.question == "How do I delete a word?")
        #expect(match.score >= 0.55)
    }

    @Test("unrelated question does not falsely match a canonical answer")
    func unrelatedQuestionFallsThrough() {
        let match = CanonicalAnswerLookup.match(
            for: "How do I split the editor into two windows?",
            in: KindaVimHelpCorpus.topics
        )

        #expect(match == nil)
    }

    @Test("preferred topic bias breaks ties toward the current help page")
    func preferredTopicBias() throws {
        let sharedQA = CanonicalQA(
            question: "How do I delete a word?",
            answer: "Type `dw`.",
            relatedCommands: [],
            fasterAlternative: nil,
            isUnsupported: false,
            terminalVimExplanation: nil
        )

        let topicA = makeTopic(id: "alpha", qa: [sharedQA])
        let topicB = makeTopic(id: "beta", qa: [sharedQA])

        let baseline = try #require(
            CanonicalAnswerLookup.match(
                for: "How do I delete a word?",
                in: [topicA, topicB]
            )
        )
        #expect(baseline.topic.id == "alpha")

        let preferred = try #require(
            CanonicalAnswerLookup.match(
                for: "How do I delete a word?",
                in: [topicA, topicB],
                preferredTopicID: "beta"
            )
        )
        #expect(preferred.topic.id == "beta")
        #expect(preferred.score > baseline.score)
    }

    private func makeTopic(id: String, qa: [CanonicalQA]) -> HelpTopic {
        HelpTopic(
            id: id,
            title: id,
            summary: "summary",
            tags: [],
            aliases: [],
            status: .supported,
            lessonIDs: [],
            relatedTopicIDs: [],
            suggestedQuestions: [],
            webSearchQuery: nil,
            videoSearchQuery: nil,
            sections: [],
            canonicalQA: qa
        )
    }
}
