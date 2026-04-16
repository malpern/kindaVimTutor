import SwiftUI

struct SidebarView: View {
    let chapters: [Chapter]
    @Binding var selectedLessonId: String?
    let progressStore: ProgressStore

    var body: some View {
        List(selection: $selectedLessonId) {
            ForEach(chapters) { chapter in
                Section {
                    ForEach(chapter.lessons) { lesson in
                        LessonRowView(
                            lesson: lesson,
                            chapterNumber: chapter.number,
                            isCompleted: progressStore.isLessonCompleted(lesson)
                        )
                        .tag(lesson.id)
                    }
                } header: {
                    ChapterRowView(chapter: chapter)
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .navigationTitle("kindaVim Tutor")
    }
}
