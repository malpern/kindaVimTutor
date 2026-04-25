import SwiftUI

/// One row in the chat thread. User bubbles sit right-aligned with an
/// accent tint; assistant bubbles sit left-aligned. Plain-text
/// assistant bubbles (fallback, greeting) use a neutral pill;
/// structured `VimAnswer` bubbles delegate to `VimAnswerBubble` so
/// they render as lesson-style cards.
struct ChatBubble: View {
    let message: ChatMessage
    var onOpenLesson: ((String) -> Void)? = nil
    var onOpenURL: ((URL) -> Void)? = nil
    var onAskAboutMotion: ((String) -> Void)? = nil
    var onOpenHelpTopic: ((String) -> Void)? = nil
    var onPractice: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if message.role == .user { Spacer(minLength: 40) }
            content
            if message.role != .user { Spacer(minLength: 40) }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch message.payload {
        case .text(let string):
            textBubble(string)
        case .answer(let display):
            VimAnswerBubble(
                display: display,
                isStreaming: message.isStreaming,
                relatedLessons: message.relatedLessons,
                canonicalSource: message.canonicalSource,
                onOpenLesson: onOpenLesson,
                onOpenURL: onOpenURL,
                onAskAboutMotion: onAskAboutMotion,
                onOpenHelpTopic: onOpenHelpTopic,
                onPractice: onPractice,
                webResults: message.webResults,
                videoShorts: message.videoShorts,
                videos: message.videos
            )
        }
    }

    private func textBubble(_ string: String) -> some View {
        Text(string)
            .font(.system(size: 14))
            .foregroundStyle(.primary)
            .textSelection(.enabled)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(fill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .textSelection(.enabled)
    }

    private var fill: some ShapeStyle {
        switch message.role {
        case .user:      return AnyShapeStyle(Color.accentColor.opacity(0.22))
        case .assistant: return AnyShapeStyle(Color.primary.opacity(0.08))
        case .system:    return AnyShapeStyle(Color.orange.opacity(0.12))
        }
    }
}
