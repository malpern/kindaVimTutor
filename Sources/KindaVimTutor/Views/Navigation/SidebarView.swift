import SwiftUI

/// Navigation rail for the lesson browser.
///
/// Implemented with `ScrollView { LazyVStack }` instead of `List` on
/// purpose: macOS 26's `List(selection:)` auto-scrolls the selected
/// row to the top of the viewport whenever the containing window
/// re-lays out (detail-view transitions, `.id()` swaps, toolbar
/// changes). For our tutor that means the expanded chapter's
/// selected lesson row gets shoved into the title-bar strip on every
/// `]` step-advance — see 2026-04-21 bug investigation. There is no
/// public API to suppress `List`'s auto-scroll, so we render the
/// rail by hand and keep selection styling local.
struct SidebarView: View {
    let chapters: [Chapter]
    @Binding var selectedLessonId: String?
    let progressStore: ProgressStore
    let inspectorState: ExerciseInspectorState

    @State private var expandedChapterId: String?

    // Which chapter contains the selected lesson?
    private var selectedChapterId: String? {
        guard let selectedLessonId else { return nil }
        return chapters.first { ch in
            ch.lessons.contains { $0.id == selectedLessonId }
        }?.id
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if inspectorState.isVisible {
                    DrillSidebarSection(state: inspectorState)
                        .padding(.horizontal, 8)
                        .padding(.top, 8)
                        .padding(.bottom, 14)
                }
                ForEach(chapters) { chapter in
                    chapterSection(chapter)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .frame(minWidth: 200)
        .navigationTitle("kindaVim Tutor")
        .onAppear {
            expandedChapterId = selectedChapterId
        }
        .onChange(of: selectedLessonId) {
            if let chId = selectedChapterId, expandedChapterId != chId {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedChapterId = chId
                }
            }
        }
    }

    @ViewBuilder
    private func chapterSection(_ chapter: Chapter) -> some View {
        let isExpanded = expandedChapterId == chapter.id
        let isChapterComplete = !chapter.lessons.isEmpty &&
            chapter.lessons.allSatisfy { progressStore.isLessonCompleted($0) }

        VStack(alignment: .leading, spacing: 2) {
            ChapterHeader(
                chapter: chapter,
                isExpanded: isExpanded,
                isComplete: isChapterComplete,
                onTap: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expandedChapterId = (expandedChapterId == chapter.id) ? nil : chapter.id
                    }
                }
            )
            if isExpanded {
                // Subtle chapter marker so prose references like "see
                // Chapter 5" have a corresponding label in the rail.
                Text("Chapter \(chapter.number)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .tracking(0.3)
                    .padding(.leading, 8)
                    .padding(.top, 2)
                    .padding(.bottom, 4)
                ForEach(chapter.lessons) { lesson in
                    SidebarLessonRow(
                        lesson: lesson,
                        chapterNumber: chapter.number,
                        isCompleted: progressStore.isLessonCompleted(lesson),
                        isSelected: selectedLessonId == lesson.id,
                        onTap: { selectedLessonId = lesson.id }
                    )
                }
            }
        }
        .padding(.bottom, 2)
    }
}

/// One clickable lesson row with its own selection-highlight state.
/// `List` would give this for free, but we're on our own — a
/// `Button` with a rounded-rect background driven by `isSelected`
/// approximates sidebar selection without the auto-scroll baggage.
private struct SidebarLessonRow: View {
    let lesson: Lesson
    let chapterNumber: Int
    let isCompleted: Bool
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            LessonRowView(
                lesson: lesson,
                chapterNumber: chapterNumber,
                isCompleted: isCompleted
            )
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected
                          ? Color.accentColor.opacity(0.28)
                          : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct ChapterHeader: View {
    let chapter: Chapter
    let isExpanded: Bool
    let isComplete: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: chapter.systemImage)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isComplete ? Color.green.opacity(0.75) : Color.secondary.opacity(0.6))
                    .frame(width: 14)
                Text(chapter.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .lineLimit(1)
                if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.green.opacity(0.75))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.quaternary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .padding(.trailing, 10)
            }
            .contentShape(Rectangle())
            .padding(.top, 6)
            .padding(.bottom, 2)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isComplete)
    }
}
