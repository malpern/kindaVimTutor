import SwiftUI
import KindaVimTutorKit

/// App entry point. Hosts a single window with a two-column split:
/// the lesson sidebar on the left and the step canvas (or welcome
/// screen) on the right.
@main
struct KindaVimTutorApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        Window("kindaVim Tutor", id: "main") {
            NavigationSplitView {
                SidebarView(
                    chapters: appState.chapters,
                    selectedLessonId: $appState.selectedLessonId,
                    progressStore: appState.progressStore
                )
            } detail: {
                if let lesson = appState.selectedLesson,
                   let chapter = appState.selectedChapter {
                    StepCanvasView(
                        lesson: lesson,
                        chapterTitle: chapter.title,
                        progressStore: appState.progressStore,
                        initialStepIndex: appState.initialStepIndex,
                        onNextLesson: { appState.goToNextLesson() }
                    )
                    .id(lesson.id)
                } else {
                    WelcomeView(onStartLearning: { appState.goToFirstLesson() })
                }
            }
            .frame(minWidth: 900, minHeight: 600)
        }
    }
}
