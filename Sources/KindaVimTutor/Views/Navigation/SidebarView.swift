import SwiftUI

struct SidebarView: View {
    let chapters: [Chapter]
    @Binding var selectedLessonId: String?

    var body: some View {
        List(selection: $selectedLessonId) {
            ForEach(chapters) { chapter in
                Section {
                    ForEach(chapter.lessons) { lesson in
                        LessonRowView(lesson: lesson, chapterNumber: chapter.number)
                            .tag(lesson.id)
                    }
                } header: {
                    ChapterRowView(chapter: chapter)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("kindaVim Tutor")
    }
}
