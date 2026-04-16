import SwiftUI

@main
struct KindaVimTutorApp: App {
    @State private var appState = AppState()
    @State private var showStats = false

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
                    LessonView(lesson: lesson, chapterTitle: chapter.title, progressStore: appState.progressStore)
                } else {
                    WelcomeView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    ModeIndicatorView(
                        mode: appState.modeMonitor.currentMode,
                        isKindaVimRunning: appState.modeMonitor.isKindaVimRunning
                    )
                }
                ToolbarItem(placement: .automatic) {
                    Button {
                        showStats.toggle()
                    } label: {
                        AchievementRingsView(
                            lessonsProgress: Double(appState.progressStore.completedLessonCount) / max(Double(appState.progressStore.totalLessons), 1),
                            exercisesProgress: Double(appState.progressStore.completedExerciseCount) / max(Double(appState.progressStore.totalExercises), 1),
                            streakProgress: 0,
                            compact: true
                        )
                    }
                    .popover(isPresented: $showStats) {
                        StatsView(progressStore: appState.progressStore)
                    }
                }
            }
            .frame(minWidth: 900, minHeight: 600)
            .onAppear {
                appState.modeMonitor.startMonitoring()
            }
        }
    }
}
