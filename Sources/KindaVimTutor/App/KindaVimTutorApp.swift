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
                if #available(macOS 26.0, *) {
                    toolbarContent.sharedBackgroundVisibility(.hidden)
                } else {
                    toolbarContent
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

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            ToolbarModeBadge(monitor: appState.modeMonitor)
        }
        ToolbarItem(placement: .automatic) {
            ToolbarStatsButton(
                progressStore: appState.progressStore,
                showStats: $showStats
            )
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
            Group {
                if let lesson = appState.selectedLesson,
                   let chapter = appState.selectedChapter {
                    StepCanvasView(
                        lesson: lesson,
                        chapterTitle: chapter.title,
                        progressStore: appState.progressStore,
                        inspectorState: appState.inspectorState,
                        modeMonitor: appState.modeMonitor,
                        onNextLesson: { appState.goToNextLesson() },
                        onJumpToLesson: { id in appState.goToLesson(id) }
                    )
                    .id(lesson.id)
                } else {
                    WelcomeView(onStartLearning: { appState.goToFirstLesson() })
                }
            }
            // Text throughout the detail view — lesson titles, prose,
            // instructions, tips, drill captions — is selectable and
            // copyable with ⌘C. Doesn't affect buttons/links or the
            // NSTextView drill editor (which has its own selection).
            .textSelection(.enabled)
        }
    }
}
