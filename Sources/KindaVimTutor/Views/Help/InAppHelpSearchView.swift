import SwiftUI

/// Custom replacement for the macOS system Help-menu search field.
/// The system Help menu uses Apple Help Book indexing, which we
/// don't ship — and even if we did, its results would open an
/// HTML viewer instead of routing into our chat/lessons/manual. This
/// sheet gives Help ⌘? the same "type to find" feeling, but indexed
/// over `KindaVimHelpCorpus` so every result routes back into the
/// tutor's native surfaces.
///
/// Keyboard model:
///  - Focus starts in the search field (arrow down moves into results).
///  - ↑/↓ moves the selection through results.
///  - Return opens the selected result via its primary action.
///  - Escape dismisses the sheet.
struct InAppHelpSearchView: View {
    let chapters: [Chapter]
    /// Open a specific curriculum lesson.
    let onOpenLesson: (String) -> Void
    /// Open a topic in the manual pane.
    let onOpenTopic: (String) -> Void
    /// Seed the chat with a freeform question.
    let onAskChat: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var query: String = ""
    @State private var selectedIndex: Int = 0
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            searchField
                .padding(16)
            Divider().opacity(0.3)
            resultsList
        }
        .frame(minWidth: 560, minHeight: 460)
        .onAppear { isFieldFocused = true }
    }

    // MARK: - Field

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
            TextField("Search kindaVim help", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .focused($isFieldFocused)
                .onChange(of: query) { _, _ in
                    selectedIndex = 0
                }
                .onSubmit(activateSelection)
            if !query.isEmpty {
                Button {
                    query = ""
                    isFieldFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        // ↑/↓ through the results without losing field focus.
        .background(arrowKeyShortcuts)
    }

    /// Hidden buttons that bind ↑/↓ arrows to selection movement.
    /// Lives in the field's background so it only fires while the
    /// sheet is frontmost — matches the Spotlight-style model.
    private var arrowKeyShortcuts: some View {
        ZStack {
            Button { moveSelection(-1) } label: { EmptyView() }
                .buttonStyle(.plain)
                .keyboardShortcut(.upArrow, modifiers: [])
                .hidden()
            Button { moveSelection(1) } label: { EmptyView() }
                .buttonStyle(.plain)
                .keyboardShortcut(.downArrow, modifiers: [])
                .hidden()
        }
    }

    // MARK: - Results

    @ViewBuilder
    private var resultsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(results.enumerated()), id: \.offset) { index, row in
                        resultRow(row, isSelected: index == selectedIndex)
                            .id(index)
                            .onTapGesture { activate(row: row) }
                    }

                    if !query.isEmpty {
                        askChatRow(isSelected: selectedIndex == results.count)
                            .id(results.count)
                            .onTapGesture { askChat() }
                    }
                }
                .padding(.vertical, 6)
            }
            .onChange(of: selectedIndex) { _, newValue in
                withAnimation(.easeInOut(duration: 0.12)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }

    private func resultRow(_ row: ResultRow, isSelected: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: row.icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isSelected ? .white.opacity(0.95) : .secondary)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? .white : .primary)
                Text(row.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "return")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(isSelected ? .white.opacity(0.8) : .clear)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(isSelected ? Color.accentColor : Color.clear,
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 10)
        .contentShape(Rectangle())
    }

    private func askChatRow(isSelected: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isSelected ? .white.opacity(0.95) : .secondary)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text("Ask chat: “\(query)”")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? .white : .primary)
                Text("Open the chat pane with this question")
                    .font(.system(size: 11))
                    .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)
            }
            Spacer()
            Image(systemName: "return")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(isSelected ? .white.opacity(0.8) : .clear)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(isSelected ? Color.accentColor : Color.clear,
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 10)
        .contentShape(Rectangle())
    }

    // MARK: - Search + routing

    /// Rows shown for the current query. Empty query → the top
    /// chapters (quick browse). Non-empty → topic matches via
    /// `KindaVimHelpCorpus.topics(forQuery:limit:)`.
    private var results: [ResultRow] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            // Empty state: surface every chapter's first lesson as a
            // jump-in point. Quick browse rather than an actual
            // search result.
            return chapters.compactMap { chapter -> ResultRow? in
                guard let lesson = chapter.lessons.first else { return nil }
                return ResultRow(
                    icon: chapter.systemImage,
                    title: "Chapter \(chapter.number).\(lesson.number) — \(lesson.title)",
                    subtitle: chapter.title,
                    action: .openLesson(lesson.id)
                )
            }
        }
        return KindaVimHelpCorpus.topics(forQuery: trimmed, limit: 8).map { topic in
            let lessonID = firstLessonID(for: topic)
            return ResultRow(
                icon: lessonID != nil ? "book.closed.fill" : "text.book.closed",
                title: topic.title,
                subtitle: topic.summary,
                action: lessonID.map { .openLesson($0) } ?? .openTopic(topic.id)
            )
        }
    }

    private func activateSelection() {
        if selectedIndex < results.count {
            activate(row: results[selectedIndex])
        } else if !query.isEmpty {
            askChat()
        }
    }

    private func activate(row: ResultRow) {
        switch row.action {
        case .openLesson(let id):
            onOpenLesson(id)
        case .openTopic(let id):
            onOpenTopic(id)
        }
        dismiss()
    }

    private func askChat() {
        onAskChat(query)
        dismiss()
    }

    private func moveSelection(_ delta: Int) {
        let count = results.count + (query.isEmpty ? 0 : 1)
        guard count > 0 else { return }
        selectedIndex = max(0, min(count - 1, selectedIndex + delta))
    }

    /// The first `lessonID` in the topic's authored list that maps to
    /// a real chapter-lesson with exercises. Skips orphaned ids.
    private func firstLessonID(for topic: HelpTopic) -> String? {
        for lessonID in topic.lessonIDs {
            for chapter in chapters {
                if chapter.lessons.contains(where: { $0.id == lessonID }) {
                    return lessonID
                }
            }
        }
        return nil
    }

    // MARK: - Row model

    private struct ResultRow {
        let icon: String
        let title: String
        let subtitle: String
        let action: Action

        enum Action {
            case openLesson(String)
            case openTopic(String)
        }
    }
}
