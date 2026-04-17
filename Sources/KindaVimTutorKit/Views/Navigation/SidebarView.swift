import SwiftUI

/// The left-hand lesson navigator. Groups lessons under tappable chapter
/// headers. Selection drives `AppState.selectedLessonId`, which the detail
/// pane reads to show the corresponding lesson canvas.
public struct SidebarView: View {
    let chapters: [Chapter]
    @Binding var selectedLessonId: String?
    let progressStore: ProgressStore

    @State private var expandedChapterId: String?

    public init(chapters: [Chapter], selectedLessonId: Binding<String?>, progressStore: ProgressStore) {
        self.chapters = chapters
        self._selectedLessonId = selectedLessonId
        self.progressStore = progressStore
    }

    // Which chapter contains the selected lesson?
    private var selectedChapterId: String? {
        guard let selectedLessonId else { return nil }
        return chapters.first { ch in
            ch.lessons.contains { $0.id == selectedLessonId }
        }?.id
    }

    public var body: some View {
        List(selection: $selectedLessonId) {
            ForEach(chapters) { chapter in
                let isExpanded = expandedChapterId == chapter.id || selectedChapterId == chapter.id

                // Chapter header — tappable to expand/collapse
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if expandedChapterId == chapter.id {
                            expandedChapterId = nil
                        } else {
                            expandedChapterId = chapter.id
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: chapter.systemImage)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .frame(width: 16)
                        Text(chapter.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.quaternary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)

                // Lessons — only visible when expanded
                if isExpanded {
                    ForEach(chapter.lessons) { lesson in
                        LessonRowView(
                            lesson: lesson,
                            chapterNumber: chapter.number,
                            isCompleted: progressStore.isLessonCompleted(lesson)
                        )
                        .tag(lesson.id)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .navigationTitle("kindaVim Tutor")
        .onAppear {
            // Auto-expand the chapter of the selected lesson
            expandedChapterId = selectedChapterId
        }
        .onChange(of: selectedLessonId) {
            // Auto-expand when selection changes
            if let chId = selectedChapterId, expandedChapterId != chId {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedChapterId = chId
                }
            }
        }
    }
}

#Preview("Sidebar") {
    @Previewable @State var selectedId: String? = PreviewSamples.lesson.id
    SidebarView(
        chapters: [PreviewSamples.chapter],
        selectedLessonId: $selectedId,
        progressStore: ProgressStore()
    )
    .frame(width: 220, height: 400)
}
