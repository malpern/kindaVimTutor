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
            // Quick smoke-test: fire a default 3-rep drill. The engine
            // generates names and targetIndices so we don't have to.
            Task { @MainActor in
                _ = await finderDrill.start(reps: parseReps(""))
            }
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
        case "notes.probe":
            Task { @MainActor in
                let surface = NotesSurface()
                let status = await surface.isUsable()
                AppLogger.shared.info("extDrill", "notesUsability",
                                      fields: ["status": "\(status)"])
                guard status == .ready else { return }
                do {
                    let prepared = try await surface.prepare(
                        body: "- practice line 1\n- practice line 2\n- practice line 3"
                    )
                    AppLogger.shared.info("extDrill", "notesPrepared",
                                          fields: ["id": prepared.documentIdentifier])
                    // Leave note visible for a few seconds, then delete.
                    try? await Task.sleep(for: .seconds(4))
                    await surface.cleanup(prepared)
                    AppLogger.shared.info("extDrill", "notesCleaned",
                                          fields: ["id": prepared.documentIdentifier])
                } catch {
                    AppLogger.shared.info("extDrill", "notesProbeError",
                                          fields: ["err": "\(error)"])
                }
            }
        case "notes.sweep":
            Task { await NotesSurface().sweepOrphans() }
        case "finder.select":
            // Usage: finder.select file07.txt
            Task {
                let ok = await FinderGrid.selectFile(named: arg)
                AppLogger.shared.info("finderDrill", "selectResult",
                                      fields: ["name": arg, "ok": ok ? "yes" : "no"])
            }
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

    /// Parses a rep spec string like "0,11 6,11 5,11" into an array
    /// of (startIndex,targetIndex) reps. Default falls back to a
    /// 3-rep drill converging on index 11.
    private func parseReps(_ arg: String) -> [FinderDrillEngine.Rep] {
        let tokens = arg.split(separator: " ").map(String.init)
        let reps: [FinderDrillEngine.Rep] = tokens.compactMap { tok in
            let parts = tok.split(separator: ",").compactMap { Int($0) }
            guard parts.count == 2 else { return nil }
            return FinderDrillEngine.Rep(startIndex: parts[0], targetIndex: parts[1])
        }
        if !reps.isEmpty { return reps }
        return [
            .init(startIndex: 0,  targetIndex: 5),
            .init(startIndex: 8,  targetIndex: 2),
            .init(startIndex: 6,  targetIndex: 11),
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
