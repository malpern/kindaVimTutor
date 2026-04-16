import SwiftUI

@main
struct KindaVimTutorApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        Window("kindaVim Tutor", id: "main") {
            NavigationSplitView {
                SidebarView(
                    chapters: appState.chapters,
                    selectedLessonId: $appState.selectedLessonId
                )
            } detail: {
                if let lesson = appState.selectedLesson,
                   let chapter = appState.selectedChapter {
                    LessonView(lesson: lesson, chapterTitle: chapter.title)
                } else {
                    WelcomeView()
                }
            }
            .frame(minWidth: 900, minHeight: 600)
        }
    }
}
