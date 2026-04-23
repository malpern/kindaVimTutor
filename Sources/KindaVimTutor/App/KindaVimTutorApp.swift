import SwiftUI

@main
struct KindaVimTutorApp: App {
    @State private var appState = AppState()
    @State private var showStats = false
    @State private var isSidebarVisible = true

    init() {
        AppLogger.shared.info("app", "launch", fields: [
            "pid": String(ProcessInfo.processInfo.processIdentifier),
            "logDir": AppLogger.shared.logDirectoryURL.path
        ])
    }

    var body: some Scene {
        Window("kindaVim Tutor", id: "main") {
            mainUI
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
                // Reap any Notes drill notes (or Mail drafts,
                // when that adapter lands) left behind by a prior
                // crashed or force-quit session. Best-effort.
                Task.detached(priority: .utility) {
                    await NotesSurface().sweepOrphans()
                    await MailSurface().sweepOrphans()
                }
            }
        }
        .commands {
            AppMenuCommands(
                isSidebarVisible: $isSidebarVisible,
                showStats: $showStats
            )
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
    @Binding var isSidebarVisible: Bool
    @Binding var showStats: Bool
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About kindaVim Tutor") {
                openWindow(id: "about")
            }
        }

        CommandGroup(before: .sidebar) {
            Button(isSidebarVisible ? "Hide Sidebar" : "Show Sidebar") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isSidebarVisible.toggle()
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
                    // Quick smoke-test with a default name list and
                    // a single target at the last slot.
                    let count = 12
                    let targets: Set<Int> = [count - 1]
                    let names = FinderDrillPrototype.generateFolderNames(
                        count: count, targetIndices: targets
                    )
                    if let result = await FinderDrillPrototype.run(names: names) {
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

/// Sidebar toggle rendered as a glass-chip icon button. Sits as an
/// overlay on the content (no NavigationSplitView), so it needs its own
/// container styling to not look like a floating icon.
private struct SidebarToggleButton: View {
    @Binding var isSidebarVisible: Bool
    @State private var isHovering = false

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isSidebarVisible.toggle()
            }
        } label: {
            Image(systemName: "sidebar.leading")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 24)
                .background {
                    if #available(macOS 26, *) {
                        Color.clear.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 7))
                    } else {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                            )
                    }
                }
        }
        .buttonStyle(.plain)
        .focusable(false)
        .opacity(isHovering ? 1 : 0.9)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .onHover { isHovering = $0 }
        .help(isSidebarVisible ? "Hide sidebar" : "Show sidebar")
        .accessibilityLabel(isSidebarVisible ? "Hide sidebar" : "Show sidebar")
    }
}

extension KindaVimTutorApp {
    @ViewBuilder
    fileprivate var mainUI: some View {
        HStack(spacing: 0) {
            if isSidebarVisible {
                SidebarView(
                    chapters: appState.chapters,
                    selectedLessonId: $appState.selectedLessonId,
                    progressStore: appState.progressStore,
                    inspectorState: appState.inspectorState
                )
                .frame(width: 260)

                Divider()
            }

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
            .textSelection(.enabled)
        }
        .overlay(alignment: .topLeading) {
            SidebarToggleButton(isSidebarVisible: $isSidebarVisible)
                .padding(.leading, isSidebarVisible ? 214 : 6)
                .padding(.top, 13)
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 12) {
                ToolbarModeBadge(monitor: appState.modeMonitor)
                ToolbarStatsButton(
                    progressStore: appState.progressStore,
                    showStats: $showStats
                )
            }
            .padding(.top, 14)
            .padding(.trailing, 18)
        }
        .coordinateSpace(name: "mainUI")
        .focusEffectDisabled()
    }
}

