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
                    LessonView(
                        lesson: lesson,
                        chapterTitle: chapter.title,
                        progressStore: appState.progressStore,
                        inspectorState: appState.inspectorState,
                        nextLesson: appState.nextLesson,
                        onNextLesson: { appState.goToNextLesson() }
                    )
                    .id(lesson.id)
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                } else {
                    WelcomeView(onStartLearning: { appState.goToFirstLesson() })
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                }
            }
            .inspector(isPresented: .init(
                get: { appState.inspectorState.isVisible },
                set: { if !$0 { appState.inspectorState.hide() } }
            )) {
                ExerciseInspectorView(state: appState.inspectorState)
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
        .commands {
            CommandGroup(after: .toolbar) {
                Button("Next Lesson") {
                    appState.goToNextLesson()
                }
                .keyboardShortcut("]", modifiers: .command)

                Divider()

                Button("Show Progress") {
                    showStats.toggle()
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
            }
        }
    }
}
