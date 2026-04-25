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
    var progressStore: ProgressStore
    var inspectorState: ExerciseInspectorState
    var onOpenLesson: (String) -> Void
    var onOpenHelpTopic: (String) -> Void

    /// Pending "Practice this concept" request. When non-nil the
    /// sheet is presented and LessonGenerator kicks off.
    @State private var practiceRequest: PracticeRequest?
    /// Latched after the practice sheet dismisses with "Browse
    /// lessons" so the TOC presents cleanly as a follow-up sheet.
    @State private var showTOC: Bool = false

    struct PracticeRequest: Identifiable {
        let id = UUID()
        let question: String
        let topicID: String?
    }

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
                                onOpenHelpTopic: onOpenHelpTopic,
                                onPractice: shouldOfferPractice(for: m)
                                    ? { startPractice(for: m) }
                                    : nil
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
        .sheet(item: $practiceRequest) { request in
            GeneratedLessonSheet(
                question: request.question,
                topicID: request.topicID,
                progressStore: progressStore,
                inspectorState: inspectorState,
                onContinue: { action in
                    switch action {
                    case .openLesson(let id):
                        // Defer navigation to the next runloop so the
                        // practice sheet can finish dismissing first.
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(60))
                            onOpenLesson(id)
                        }
                    case .openTableOfContents:
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(60))
                            showTOC = true
                        }
                    }
                }
            )
        }
        .sheet(isPresented: $showTOC) {
            TableOfContentsView(
                chapters: chapters,
                progressStore: progressStore,
                onOpenLesson: { id in
                    // Same deferred hand-off — dismiss the TOC sheet
                    // first so navigation doesn't mutate state while
                    // the sheet is still dismissing.
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(60))
                        onOpenLesson(id)
                    }
                }
            )
        }
    }

    /// Only offer practice for substantive assistant answers, not
    /// the greeting pill or streaming placeholders. We also gate on
    /// OpenAI being available — the Apple on-device path can't
    /// generate drills reliably (context too tight, structured
    /// output less robust).
    private func shouldOfferPractice(for message: ChatMessage) -> Bool {
        guard message.role == .assistant, !message.isStreaming else { return false }
        guard AIBackendSettings.backend == .openAI,
              AIBackendSettings.openAIKey != nil
        else { return false }
        switch message.payload {
        case .text: return false
        case .answer(let display):
            return !display.answer.isEmpty && !display.isUnsupported
        }
    }

    /// Walks backwards from the tapped assistant bubble to find the
    /// user question that triggered it — that's the richest signal
    /// for the drill generator. Falls back to the assistant answer
    /// text if no user message is present.
    private func startPractice(for message: ChatMessage) {
        guard let index = engine.messages.firstIndex(where: { $0.id == message.id })
        else { return }
        let prior = engine.messages[..<index].reversed()
        let question = prior.first(where: { $0.role == .user })?.plainText
            ?? message.plainText
        practiceRequest = PracticeRequest(
            question: question,
            topicID: message.canonicalSource?.topicID
        )
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
