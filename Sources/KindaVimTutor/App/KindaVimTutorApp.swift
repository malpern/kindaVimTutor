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
            mainUI
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    ToolbarModeBadge(monitor: appState.modeMonitor)
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
            .environment(appState.modeMonitor)
            .onAppear {
                appState.modeMonitor.startMonitoring()
                if ProcessInfo.processInfo.environment["KINDAVIMTUTOR_ENABLE_CHANNEL"] == "1" {
                    AppCommandChannel.shared.start(appState: appState)
                }
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

        Settings {
            SettingsView(progressStore: appState.progressStore)
        }
    }

    @ViewBuilder
    private var mainUI: some View {
        NavigationSplitView {
            SidebarView(
                chapters: appState.chapters,
                selectedLessonId: $appState.selectedLessonId,
                progressStore: appState.progressStore,
                inspectorState: appState.inspectorState
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
    }
}
