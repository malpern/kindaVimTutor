import SwiftUI

@main
struct KindaVimTutorApp: App {
    @State private var appState = AppState()
    @State private var showStats = false

    init() {
        AppLogger.shared.info("app", "launch", fields: [
            "pid": String(ProcessInfo.processInfo.processIdentifier),
            "logDir": AppLogger.shared.logDirectoryURL.path
        ])
    }

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
                        inspectorState: appState.inspectorState,
                        onNextLesson: { appState.goToNextLesson() }
                    )
                    .id(lesson.id)
                } else {
                    WelcomeView(onStartLearning: { appState.goToFirstLesson() })
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
                Button("Show Progress") {
                    showStats.toggle()
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
            }
        }
    }
}
