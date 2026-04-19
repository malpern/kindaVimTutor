import SwiftUI

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
        List(selection: $selectedLessonId) {
            if inspectorState.isVisible {
                Section {
                    DrillSidebarSection(state: inspectorState)
                        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 14, trailing: 8))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }

            ForEach(chapters) { chapter in
                chapterSection(chapter)
            }
        }
        .listStyle(.sidebar)
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

        Section {
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
        } header: {
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
        }
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
