import Foundation

enum HelpTopicStatus: String {
    case supported
    case partial
    case unsupported

    var label: String {
        switch self {
        case .supported: "Supported"
        case .partial: "Partially supported"
        case .unsupported: "Not supported"
        }
    }
}

struct HelpTopicSection: Equatable, Sendable {
    let title: String
    let body: String
}

struct HelpTopic: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let summary: String
    let tags: [String]
    let aliases: [String]
    let status: HelpTopicStatus
    let lessonIDs: [String]
    let relatedTopicIDs: [String]
    let suggestedQuestions: [String]
    let webSearchQuery: String?
    let videoSearchQuery: String?
    let sections: [HelpTopicSection]
    /// Hand-authored (and smart-model-verified) Q&A pairs. Serve
    /// these directly when a user question matches closely enough —
    /// bypasses the on-device model for the common-case questions
    /// that we know the reliable answer for.
    let canonicalQA: [CanonicalQA]
}

/// A pre-generated answer in the same shape as `VimAnswer`, authored
/// offline by a smart model and human-reviewed. Retrieved at
/// runtime by `CanonicalAnswerLookup` and rendered by the chat
/// without invoking the on-device model.
struct CanonicalQA: Equatable, Sendable {
    let question: String
    let answer: String
    let relatedCommands: [RelatedCommandEntry]
    let fasterAlternative: String?
    let isUnsupported: Bool
    let terminalVimExplanation: String?

    struct RelatedCommandEntry: Equatable, Sendable {
        let command: String
        let summary: String
    }
}

struct HelpLessonRef: Identifiable, Equatable {
    let id: String
    let title: String
    let chapterNumber: Int
    let lessonNumber: Int
}
