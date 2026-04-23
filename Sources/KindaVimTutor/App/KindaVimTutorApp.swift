import SwiftUI

@main
struct KindaVimTutorApp: App {
    @State private var appState = AppState()
    @State private var showStats = false
    @State private var isSidebarVisible = true
    @State private var primaryPaneMode: PrimaryPaneMode = .lesson
    @State private var manualNavigation = ManualNavigationState()
    @State private var chatEngine = ChatEngine()
    /// Set when the user navigated to a lesson FROM a help surface
    /// (chat or manual) — gives the lesson canvas a back button to
    /// return. Cleared on any subsequent non-help navigation (sidebar
    /// click, next-lesson, etc.) so the trail is shallow by design.
    @State private var returnToHelpMode: PrimaryPaneMode?

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
                showStats: $showStats,
                primaryPaneMode: $primaryPaneMode
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

private enum PrimaryPaneMode {
    case lesson
    case chat
    case manual
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
    @Binding var primaryPaneMode: PrimaryPaneMode
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About kindaVim Tutor") {
                openWindow(id: "about")
            }
        }

        CommandGroup(replacing: .help) {
            Button("kindaVim Tutor Help") {
                primaryPaneMode = .chat
            }
            // Apple's standard Help shortcut: ⌘⇧/ (aka ⌘?).
            // Binding the slash with [.command, .shift] registers it
            // reliably on US layouts and matches the system-drawn
            // `⌘?` glyph in the menu.
            .keyboardShortcut("/", modifiers: [.command, .shift])
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

/// Pill-shaped back-chevron that appears on the lesson canvas when
/// the user arrived via a help surface (chat or manual). One click
/// returns them to wherever they came from. Styling matches the
/// sidebar-toggle glass chip so they read as a pair.
private struct BackToHelpButton: View {
    let destination: PrimaryPaneMode
    let onTap: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 5) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .bold))
                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(.primary.opacity(0.88))
            .padding(.horizontal, 10)
            .frame(height: 24)
            .background {
                if #available(macOS 26, *) {
                    Color.clear.glassEffect(
                        .regular.interactive(),
                        in: .rect(cornerRadius: 7)
                    )
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
        .help("Back to \(label)")
        .accessibilityLabel("Back to \(label)")
    }

    private var label: String {
        switch destination {
        case .chat:   return "Help"
        case .manual: return "Manual"
        case .lesson: return "Lesson"
        }
    }
}

extension KindaVimTutorApp {
    @ViewBuilder
    fileprivate var mainUI: some View {
        HStack(spacing: 0) {
            if primaryPaneMode == .manual {
                HelpBrowserView(
                    corpus: KindaVimHelpCorpus.shared,
                    selectedTopicID: Binding(
                        get: { manualNavigation.selectedTopicID },
                        set: { manualNavigation.selectedTopicID = $0 }
                    ),
                    currentLesson: appState.selectedLesson,
                    chapters: appState.chapters,
                    canGoBack: manualNavigation.canGoBack,
                    onGoBack: popManualTopic,
                    onSelectTopic: selectManualTopic,
                    onOpenLesson: { id in
                        returnToHelpMode = .manual
                        appState.goToLesson(id)
                        primaryPaneMode = .lesson
                    },
                    onAskQuestion: { topic, question in
                        manualNavigation.selectedTopicID = topic.id
                        returnToHelpMode = .manual
                        primaryPaneMode = .chat
                        chatEngine.input = question
                        chatEngine.send()
                    }
                )
                .railView

                Divider()
            } else if isSidebarVisible {
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
                if primaryPaneMode == .chat {
                    ChatView(
                        engine: chatEngine,
                        lesson: appState.selectedLesson,
                        chapterTitle: appState.selectedChapter?.title,
                        chapters: appState.chapters,
                        helpTopicID: manualNavigation.selectedTopicID,
                        onOpenLesson: { id in
                            // Defer state mutation by one tick so the
                            // Button action can finish before the
                            // ChatView tears down. Mutating state
                            // during the button's own view update
                            // caused an assertion / crash.
                            Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(10))
                                returnToHelpMode = .chat
                                appState.goToLesson(id)
                                primaryPaneMode = .lesson
                            }
                        },
                        onOpenHelpTopic: { topicID in
                            // Same deferred-mutation pattern — we're
                            // swapping ChatView for the manual pane,
                            // so let the button action finish first.
                            Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(10))
                                manualNavigation.selectedTopicID = topicID
                                returnToHelpMode = .chat
                                primaryPaneMode = .manual
                            }
                        }
                    )
                } else if primaryPaneMode == .manual {
                    HelpBrowserView(
                        corpus: KindaVimHelpCorpus.shared,
                        selectedTopicID: Binding(
                            get: { manualNavigation.selectedTopicID },
                            set: { manualNavigation.selectedTopicID = $0 }
                        ),
                        currentLesson: appState.selectedLesson,
                        chapters: appState.chapters,
                        canGoBack: manualNavigation.canGoBack,
                        onGoBack: popManualTopic,
                        onSelectTopic: selectManualTopic,
                        onOpenLesson: { id in
                            returnToHelpMode = .manual
                            appState.goToLesson(id)
                            primaryPaneMode = .lesson
                        },
                        onAskQuestion: { topic, question in
                            manualNavigation.selectedTopicID = topic.id
                            returnToHelpMode = .manual
                            primaryPaneMode = .chat
                            chatEngine.input = question
                            chatEngine.send()
                        }
                    )
                } else if let lesson = appState.selectedLesson,
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
            HStack(spacing: 10) {
                // Sidebar toggle is irrelevant in the manual — that
                // pane has its own left rail. Everywhere else, show
                // it so the student can collapse the lesson rail.
                if primaryPaneMode != .manual {
                    SidebarToggleButton(isSidebarVisible: $isSidebarVisible)
                }
                // Back-to-help chip whenever the user trailed off a
                // help surface onto any other pane (lesson, chat, or
                // manual — e.g. opening a canonical source from chat
                // lands you in the manual).
                if let returnMode = returnToHelpMode,
                   returnMode != primaryPaneMode {
                    BackToHelpButton(destination: returnMode) {
                        primaryPaneMode = returnMode
                        returnToHelpMode = nil
                    }
                }
            }
            .padding(.leading, overlayLeading)
            .padding(.top, 13)
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 12) {
                HelpChatButton(
                    isChatActive: Binding(
                        get: { primaryPaneMode == .chat },
                        set: { primaryPaneMode = $0 ? .chat : .lesson }
                    ),
                    availability: chatEngine.availability
                )
                ManualHelpButton(
                    isActive: Binding(
                        get: { primaryPaneMode == .manual },
                        set: { newValue in
                            if newValue {
                                openManual()
                            } else {
                                primaryPaneMode = .lesson
                            }
                        }
                    )
                )
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
        .onChange(of: appState.selectedLessonId) { _, _ in
            // Sidebar selection closes help surfaces so the student
            // lands on the clicked lesson's canvas.
            if primaryPaneMode != .lesson {
                primaryPaneMode = .lesson
            }
            // Sidebar nav is explicit forward motion — don't offer a
            // back-to-help trail after that.
            returnToHelpMode = nil
        }
    }

    /// Leading inset for the top-left overlay (sidebar toggle +
    /// back-to-help chip). Depends on which pane owns the leftmost
    /// column at the moment so the overlay clears it.
    private var overlayLeading: CGFloat {
        switch primaryPaneMode {
        case .manual:
            return 267  // manual rail is 260 wide + ~6 breathing room
        case .lesson, .chat:
            return isSidebarVisible ? 214 : 6
        }
    }

    private func openManual() {
        let preferredTopicID = appState.selectedLesson
            .flatMap { KindaVimHelpCorpus.shared.topic(forLessonID: $0.id)?.id }
        let fallbackTopicID = KindaVimHelpCorpus.shared.topics.first?.id
        manualNavigation.prepareToOpenManual(
            preferredTopicID: preferredTopicID,
            fallbackTopicID: fallbackTopicID,
            preserveHistory: primaryPaneMode == .manual
        )
        primaryPaneMode = .manual
    }

    private func selectManualTopic(_ topicID: String) {
        manualNavigation.selectTopic(topicID)
    }

    private func popManualTopic() {
        manualNavigation.popBack()
    }
}
