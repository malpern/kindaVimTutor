import Testing
@testable import KindaVimTutor

@Suite("Manual navigation state")
struct ManualNavigationStateTests {
    @Test("opening manual selects preferred topic and clears history when entering fresh")
    func prepareToOpenManualFresh() {
        var state = ManualNavigationState(
            selectedTopicID: "delete-word",
            history: ["dedication", "find-character"]
        )

        state.prepareToOpenManual(
            preferredTopicID: "macros",
            fallbackTopicID: "dedication",
            preserveHistory: false
        )

        #expect(state.selectedTopicID == "macros")
        #expect(!state.canGoBack)
    }

    @Test("opening manual without preferred topic falls back only when needed")
    func prepareToOpenManualFallbackBehavior() {
        var empty = ManualNavigationState()
        empty.prepareToOpenManual(
            preferredTopicID: nil,
            fallbackTopicID: "dedication",
            preserveHistory: false
        )
        #expect(empty.selectedTopicID == "dedication")

        var existing = ManualNavigationState(selectedTopicID: "delete-word")
        existing.prepareToOpenManual(
            preferredTopicID: nil,
            fallbackTopicID: "dedication",
            preserveHistory: false
        )
        #expect(existing.selectedTopicID == "delete-word")
    }

    @Test("selecting a new topic pushes current topic onto history")
    func selectTopicPushesHistory() {
        var state = ManualNavigationState(selectedTopicID: "dedication")

        state.selectTopic("delete-word")
        #expect(state.selectedTopicID == "delete-word")
        #expect(state.canGoBack)

        state.selectTopic("find-character")
        #expect(state.selectedTopicID == "find-character")
        #expect(state == ManualNavigationState(
            selectedTopicID: "find-character",
            history: ["dedication", "delete-word"]
        ))
    }

    @Test("reselecting current topic does not duplicate history")
    func reselectingCurrentTopicIsNoOp() {
        var state = ManualNavigationState(
            selectedTopicID: "delete-word",
            history: ["dedication"]
        )

        state.selectTopic("delete-word")
        #expect(state == ManualNavigationState(
            selectedTopicID: "delete-word",
            history: ["dedication"]
        ))
    }

    @Test("popBack restores previous topic and shrinks history")
    func popBack() {
        var state = ManualNavigationState(
            selectedTopicID: "find-character",
            history: ["dedication", "delete-word"]
        )

        state.popBack()
        #expect(state.selectedTopicID == "delete-word")
        #expect(state == ManualNavigationState(
            selectedTopicID: "delete-word",
            history: ["dedication"]
        ))

        state.popBack()
        #expect(state.selectedTopicID == "dedication")
        #expect(!state.canGoBack)

        state.popBack()
        #expect(state.selectedTopicID == "dedication")
    }
}
