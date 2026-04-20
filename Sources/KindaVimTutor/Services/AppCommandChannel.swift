import SwiftUI
import AppKit

/// File-polled command channel so an external harness can drive the app without
/// AppleScript / Accessibility entitlements.
///
/// The app reads one command per line from `commands.in` under the log directory,
/// executes it, and truncates the file. The harness appends commands with `echo`.
/// A mirror file `state.json` is kept up to date so the harness can read
/// state transitions synchronously.
@Observable
@MainActor
final class AppCommandChannel {
    struct State: Codable, Sendable {
        var selectedLessonId: String?
        var stepIndex: Int
        var stepCount: Int
        var stepId: String
        var stepKind: String
        var editorFocused: Bool
        var drillComplete: Bool
        var updatedAt: String
    }

    static let shared = AppCommandChannel()

    private var timer: Timer?
    private let commandsURL: URL
    private let stateURL: URL
    private let isoFormatter: ISO8601DateFormatter
    private weak var appState: AppState?
    private weak var currentController: LessonStepController?
    private let finderDrill = FinderDrillEngine()

    private init() {
        let logDir = AppLogger.shared.logDirectoryURL
        commandsURL = logDir.appendingPathComponent("commands.in")
        stateURL = logDir.appendingPathComponent("state.json")
        isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }

    var commandsFileURL: URL { commandsURL }
    var stateFileURL: URL { stateURL }

    /// Start polling. Idempotent.
    func start(appState: AppState) {
        self.appState = appState
        guard timer == nil else { return }
        AppLogger.shared.info("channel", "start", fields: [
            "commands": commandsURL.path,
            "state": stateURL.path
        ])
        try? "".write(to: commandsURL, atomically: true, encoding: .utf8)
        writeState()

        timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func registerController(_ controller: LessonStepController?) {
        currentController = controller
        writeState()
    }

    func notifyStateChanged() {
        writeState()
    }

    private func tick() {
        processCommands()
        writeState()
    }

    private func processCommands() {
        guard FileManager.default.fileExists(atPath: commandsURL.path),
              let contents = try? String(contentsOf: commandsURL, encoding: .utf8),
              !contents.isEmpty else {
            return
        }
        try? "".write(to: commandsURL, atomically: true, encoding: .utf8)
        for raw in contents.split(separator: "\n") {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            execute(line)
        }
    }

    private func execute(_ command: String) {
        AppLogger.shared.info("channel", "command", fields: ["cmd": command])
        let parts = command.split(separator: " ", maxSplits: 1).map(String.init)
        let verb = parts.first ?? ""
        let arg = parts.count > 1 ? parts[1] : ""

        switch verb {
        case "next":
            currentController?.nextStep()
        case "prev", "previous":
            currentController?.previousStep()
        case "goto":
            if let index = Int(arg) {
                currentController?.goToStep(index)
            }
        case "selectLesson":
            appState?.selectedLessonId = arg.isEmpty ? nil : arg
        case "startFirstLesson":
            appState?.goToFirstLesson()
        case "nextLesson":
            appState?.goToNextLesson()
        case "type":
            sendKeystrokes(arg)
        case "key":
            sendNamedKey(arg)
        case "finder.prototype":
            Task { await FinderDrillPrototype.run() }
        case "finder.reprobe":
            let s = FinderDrillPrototype.readFinderSelection() ?? "<none>"
            AppLogger.shared.info("finderDrill", "reprobe", fields: ["selection": s])
        case "finder.run":
            // Usage: finder.run file01.txt,file06.txt file02.txt,file12.txt
            // Each space-separated token is "start,target".
            // Falls back to a default 3-rep sequence if no args.
            let reps = parseReps(arg)
            Task { @MainActor in
                finderDrill.onDrillCompleted = { [weak finderDrill] in
                    guard let finderDrill else { return }
                    FinderDrillPanel.shared.finish(engine: finderDrill)
                }
                let ok = await finderDrill.start(reps: reps)
                if ok, let monitor = self.appState?.modeMonitor {
                    FinderDrillPanel.shared.show(engine: finderDrill,
                                                 modeMonitor: monitor)
                }
                AppLogger.shared.info("finderDrill", "runStart",
                                      fields: ["ok": ok ? "yes" : "no",
                                               "reps": "\(reps.count)"])
            }
        case "finder.stop":
            finderDrill.stop()
            FinderDrillPanel.shared.hide()
        case "finder.select":
            // Usage: finder.select file07.txt
            let ok = FinderGrid.selectFile(named: arg)
            AppLogger.shared.info("finderDrill", "selectResult",
                                  fields: ["name": arg, "ok": ok ? "yes" : "no"])
        case "finder.grid":
            FinderGrid.resizeFocusedFinderWindow(to: CGSize(width: 640, height: 440))
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                logFinderLayout(FinderGrid.readLayout(), tag: "gridCell")
            }
        default:
            AppLogger.shared.warn("channel", "unknown command", fields: ["cmd": command])
        }
    }

    private func sendKeystrokes(_ text: String) {
        guard let window = NSApp.keyWindow ?? NSApp.mainWindow,
              let responder = window.firstResponder else {
            AppLogger.shared.warn("channel", "type ignored — no first responder")
            return
        }
        for ch in text {
            if let event = NSEvent.keyEvent(
                with: .keyDown,
                location: .zero,
                modifierFlags: [],
                timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: window.windowNumber,
                context: nil,
                characters: String(ch),
                charactersIgnoringModifiers: String(ch),
                isARepeat: false,
                keyCode: 0
            ) {
                window.sendEvent(event)
            }
            _ = responder // keep compiler quiet if unused
        }
    }

    /// Parses a rep spec string like "file01.txt,file06.txt file02.txt,file12.txt"
    /// into an array of reps. Default falls back to a 3-rep drill with
    /// corners of a standard 12-file grid.
    private func parseReps(_ arg: String) -> [FinderDrillEngine.Rep] {
        let tokens = arg.split(separator: " ").map(String.init)
        let reps: [FinderDrillEngine.Rep] = tokens.compactMap { tok in
            let parts = tok.split(separator: ",").map(String.init)
            guard parts.count == 2 else { return nil }
            return FinderDrillEngine.Rep(start: parts[0], target: parts[1])
        }
        if !reps.isEmpty { return reps }
        return [
            .init(start: "folder01", target: "folder06"),
            .init(start: "folder12", target: "folder01"),
            .init(start: "folder07", target: "folder04"),
        ]
    }

    private func logFinderLayout(_ layout: FinderGrid.Layout?, tag: String) {
        guard let layout else {
            AppLogger.shared.info("finderDrill", "gridEmpty", fields: [:])
            return
        }
        AppLogger.shared.info("finderDrill", "gridSize", fields: [
            "rows": "\(layout.rowCount)",
            "cols": "\(layout.colCount)",
            "filled": "\(layout.filled.count)"
        ])
        for cell in layout.filled.sorted(by: { ($0.row, $0.col) < ($1.row, $1.col) }) {
            AppLogger.shared.info("finderDrill", tag, fields: [
                "name": cell.name,
                "row": "\(cell.row)",
                "col": "\(cell.col)"
            ])
        }
    }

    private func sendNamedKey(_ name: String) {
        // Maps a small set of convenient aliases to characters the canvas knows.
        let keys: [String: String] = [
            "space": " ",
            "l": "l",
            "h": "h",
            "forward": "l",
            "backward": "h"
        ]
        sendKeystrokes(keys[name] ?? name)
    }

    private func writeState() {
        guard let appState else { return }
        let controller = currentController
        let kind: String
        let stepId: String
        switch controller?.currentStep {
        case .title(let lesson, _): kind = "title"; stepId = lesson.id
        case .content(let id, _): kind = "content"; stepId = id
        case .drill(let exercise, _): kind = "drill"; stepId = exercise.id
        case .modeSequence(let id, _): kind = "modeseq"; stepId = id
        case .finderDrill(let id, _): kind = "finderdrill"; stepId = id
        case .none: kind = "none"; stepId = ""
        }
        let state = State(
            selectedLessonId: appState.selectedLessonId,
            stepIndex: controller?.currentStepIndex ?? -1,
            stepCount: controller?.stepCount ?? 0,
            stepId: stepId,
            stepKind: kind,
            editorFocused: false, // canvas only knows via internal state; not piped here yet
            drillComplete: false,
            updatedAt: isoFormatter.string(from: Date())
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(state) {
            try? data.write(to: stateURL, options: .atomic)
        }
    }
}
