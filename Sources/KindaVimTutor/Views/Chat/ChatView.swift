import SwiftUI
import AppKit

/// Full-pane chat UI. Replaces the step canvas when the user clicks
/// the `?` header button. Scrolls to the bottom as new messages
/// arrive so the latest streaming token is always on-screen.
struct ChatView: View {
    @Bindable var engine: ChatEngine
    var lesson: Lesson?
    var chapterTitle: String?
    var chapters: [Chapter]
    var helpTopicID: String? = nil
    var onOpenLesson: (String) -> Void
    var onOpenHelpTopic: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        ForEach(engine.messages) { m in
                            ChatBubble(
                                message: m,
                                onOpenLesson: onOpenLesson,
                                onOpenURL: openURL,
                                onAskAboutMotion: askAbout,
                                onOpenHelpTopic: onOpenHelpTopic
                            )
                            .id(m.id)
                        }
                    }
                    .textSelection(.enabled)
                    .padding(.horizontal, 20)
                    // Clear the 14pt-top/24pt-tall header overlay
                    // (mode chip + ?/Manual/stats buttons) so
                    // bubbles don't slide behind them.
                    .padding(.top, 60)
                    .padding(.bottom, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onChange(of: engine.messages.last?.id) { _, newID in
                    guard let newID else { return }
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(newID, anchor: .bottom)
                    }
                }
                .onChange(of: lastBubbleSignature) { _, _ in
                    guard let id = engine.messages.last?.id else { return }
                    proxy.scrollTo(id, anchor: .bottom)
                }
            }

            Divider().opacity(0.3)
            ChatInputBar(engine: engine)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            engine.activate(
                lesson: lesson,
                chapterTitle: chapterTitle,
                chapters: chapters,
                helpTopicID: helpTopicID
            )
        }
    }

    /// Hash signature of the last assistant bubble's rendered content
    /// so we can scroll when a streaming answer grows.
    private var lastBubbleSignature: String {
        guard let last = engine.messages.last else { return "" }
        switch last.payload {
        case .text(let s): return s
        case .answer(let a):
            return "\(a.answer)|\(a.relatedCommands.count)|\(a.fasterAlternative ?? "")"
        }
    }

    private func openURL(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    /// Injects a user message asking about a specific motion and
    /// triggers the model to respond. Used when the user taps a
    /// keycap in the "Related" row.
    private func askAbout(_ motion: String) {
        engine.input = "Explain `\(motion)`"
        engine.send()
    }
}
