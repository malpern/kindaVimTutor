import Foundation

/// A message displayed in the chat view. Holds either plain text
/// (user input, fallback system messages) or a structured
/// `VimAnswerDisplay` that the assistant bubble renders as lesson
/// cards.
struct ChatMessage: Identifiable, Equatable {
    enum Role { case assistant, user, system }

    enum Payload: Equatable {
        case text(String)
        case answer(VimAnswerDisplay)
    }

    let id = UUID()
    let role: Role
    var payload: Payload
    var isStreaming: Bool = false
    /// Web search results attached to this assistant message.
    /// Fetched after the answer streams in, when the model requests
    /// supplementary references via `webSearchQuery`.
    var webResults: [WebResult] = []
    /// YouTube shorts + videos attached to this assistant message.
    /// Fetched after the answer, only when the model requests them
    /// via `videoSearchQuery`.
    var videoShorts: [VideoResult] = []
    var videos: [VideoResult] = []
    /// Curriculum lessons that cover this topic, surfaced after the
    /// answer by matching keywords against lesson titles. Displayed
    /// inline as clickable rows.
    var relatedLessons: [RelatedLessonRef] = []
    /// When the answer was served from the canonical corpus, the
    /// source topic ID + title so the chat can offer a click-through
    /// to the reference entry the user can read in full.
    var canonicalSource: CanonicalSource?

    struct CanonicalSource: Equatable {
        let topicID: String
        let topicTitle: String
    }

    struct RelatedLessonRef: Identifiable, Equatable {
        let id: String
        let title: String
        let chapterNumber: Int
        let lessonNumber: Int
    }

    var plainText: String {
        switch payload {
        case .text(let s): return s
        case .answer(let a): return a.answer
        }
    }
}
