import SwiftUI

@main
struct KindaVimTutorApp: App {
    @State private var appState = AppState()
    @State private var showStats = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

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
                // Reschedule the streak reminder on every launch.
                // Opening the app doesn't count as "practice" — only
                // completing an exercise does — so the tier might
                // still be e.g. .daily and needs its reminder pushed
                // back to tomorrow.
                Task {
                    await NotificationService.shared.rescheduleIfNeeded(
                        progress: appState.progressStore.progress,
                        prefs: NotificationPreferencesStorage.current()
                    )
                }
            }
        }
        .commands {
            AppMenuCommands(columnVisibility: $columnVisibility, showStats: $showStats)
        }

        Window("About kindaVim Tutor", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Settings {
            SettingsView(progressStore: appState.progressStore)
        }
    }

}

@MainActor
private final class DebugObserverBox {
    static let shared = DebugObserverBox()
    let observer = FinderSelectionObserver()
    var isRunning = false
}

private struct AppMenuCommands: Commands {
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @Binding var showStats: Bool
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About kindaVim Tutor") {
                openWindow(id: "about")
            }
        }

        // Put sidebar toggle in the View menu at the standard slot
        // (CommandGroup(before: .sidebar) replaces the empty system
        // sidebar slot). `⌘⌃S` matches Xcode's toggle-navigator
        // shortcut, which is the closest established convention for
        // dev-tool apps on macOS.
        CommandGroup(before: .sidebar) {
            Button(columnVisibility == .detailOnly ? "Show Sidebar" : "Hide Sidebar") {
                withAnimation(.easeInOut(duration: 0.25)) {
                    columnVisibility = (columnVisibility == .detailOnly)
                        ? .automatic
                        : .detailOnly
                }
            }
            .keyboardShortcut("s", modifiers: [.command, .control])
        }

        CommandGroup(after: .toolbar) {
            Button("Show Progress") {
                showStats.toggle()
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
        }

        CommandMenu("Debug") {
            Button("Request Accessibility Permission") {
                _ = FinderDrillPrototype.requestAccessibility()
            }
            Divider()
            Button("Run Finder Drill Prototype") {
                Task {
                    if let result = await FinderDrillPrototype.run() {
                        AppLogger.shared.info("finderDrill", "result", fields: [
                            "folder": result.folder.path,
                            "target": result.target.lastPathComponent,
                            "start": result.start.lastPathComponent,
                            "selection": result.selectionReadback
                        ])
                    }
                }
            }
            Button("Re-probe Finder Selection") {
                let s = FinderDrillPrototype.readFinderSelection() ?? "<none>"
                AppLogger.shared.info("finderDrill", "reprobe", fields: ["selection": s])
            }
            .keyboardShortcut("f", modifiers: [.command, .shift, .control])
            Button("Toggle Live Finder Selection Observer") {
                let box = DebugObserverBox.shared
                if box.isRunning {
                    box.observer.stop()
                    box.isRunning = false
                    AppLogger.shared.info("finderDrill", "observerToggled",
                                          fields: ["state": "off"])
                } else {
                    let ok = box.observer.start { selection in
                        AppLogger.shared.info("finderDrill", "observerChange",
                                              fields: ["selection": selection ?? "<none>"])
                    }
                    box.isRunning = ok
                    AppLogger.shared.info("finderDrill", "observerToggled",
                                          fields: ["state": ok ? "on" : "failed"])
                }
            }
            .keyboardShortcut("o", modifiers: [.command, .shift, .control])
            Button("Resize Finder Window + Dump Grid") {
                FinderGrid.resizeFocusedFinderWindow(
                    to: CGSize(width: 640, height: 440)
                )
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(250))
                    guard let layout = FinderGrid.readLayout() else {
                        AppLogger.shared.info("finderDrill", "gridEmpty", fields: [:])
                        return
                    }
                    AppLogger.shared.info("finderDrill", "gridSize", fields: [
                        "rows": "\(layout.rowCount)",
                        "cols": "\(layout.colCount)",
                        "filled": "\(layout.filled.count)"
                    ])
                    for cell in layout.filled.sorted(by: { ($0.row, $0.col) < ($1.row, $1.col) }) {
                        AppLogger.shared.info("finderDrill", "gridCell", fields: [
                            "name": cell.name,
                            "row": "\(cell.row)",
                            "col": "\(cell.col)"
                        ])
                    }
                }
            }
            .keyboardShortcut("g", modifiers: [.command, .shift, .control])
        }
    }
}

extension KindaVimTutorApp {
    @ToolbarContentBuilder
    fileprivate var toolbarContent: some ToolbarContent {
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
        NavigationSplitView(columnVisibility: $columnVisibility) {
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
