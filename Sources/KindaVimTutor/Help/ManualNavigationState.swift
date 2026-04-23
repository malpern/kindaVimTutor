import Foundation

struct ManualNavigationState: Equatable, Sendable {
    var selectedTopicID: String?
    private(set) var history: [String] = []

    var canGoBack: Bool {
        !history.isEmpty
    }

    mutating func prepareToOpenManual(
        preferredTopicID: String?,
        fallbackTopicID: String?,
        preserveHistory: Bool
    ) {
        if !preserveHistory {
            history = []
        }
        if let preferredTopicID {
            selectedTopicID = preferredTopicID
        } else if selectedTopicID == nil {
            selectedTopicID = fallbackTopicID
        }
    }

    mutating func selectTopic(_ topicID: String) {
        guard selectedTopicID != topicID else { return }
        if let current = selectedTopicID {
            history.append(current)
        }
        selectedTopicID = topicID
    }

    mutating func popBack() {
        guard let previous = history.popLast() else { return }
        selectedTopicID = previous
    }
}
