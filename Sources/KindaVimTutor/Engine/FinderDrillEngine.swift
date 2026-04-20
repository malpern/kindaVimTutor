import AppKit
import Foundation
import Observation

/// Runs a Finder-navigation drill: opens a tmp folder with a grid of
/// files, walks the student through a series of reps where they must
/// move the selection from a start file to a target file using hjkl
/// (via kindaVim) or arrow keys. Mirrors `ExerciseEngine`'s state
/// machine so the existing coaching/progress surfaces can be adapted.
///
/// This engine is standalone for now — not yet wired into Curriculum
/// or the lesson step controller. Invoked from the Debug menu / app
/// command channel until it's exercised enough to graduate.
@Observable
@MainActor
final class FinderDrillEngine {
    enum State: Equatable {
        case idle
        case preparing
        case active
        case repCompleted
        case drillCompleted
    }

    /// One rep's definition: start the user at `start`, they must end
    /// with `target` selected. Names are filenames within the tmp
    /// folder (e.g. "file05.txt").
    struct Rep: Equatable {
        let start: String
        let target: String
    }

    struct RepResult: Equatable {
        let rep: Rep
        let moves: Int
        let timeSeconds: TimeInterval
    }

    private(set) var state: State = .idle
    private(set) var folder: URL?
    private(set) var reps: [Rep] = []
    private(set) var completedRepIndex: Int = 0
    private(set) var moveCount: Int = 0
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var results: [RepResult] = []
    /// The selection we've most recently observed. Used to dedupe the
    /// AXObserver's 2–3x redundant fires per real change, and as the
    /// pre-state so rep-start self-selection isn't scored as a move.
    private(set) var currentSelection: String?

    private let observer = FinderSelectionObserver()
    private var startTime: Date?
    private var timer: Timer?
    private var files: [URL] = []

    var currentRep: Rep? {
        guard completedRepIndex < reps.count else { return nil }
        return reps[completedRepIndex]
    }

    // MARK: - Lifecycle

    /// Starts a drill: materialize tmp folder, open Finder, install
    /// the AX observer, run reps sequentially. Returns false if the
    /// setup fails (e.g. AX not trusted or Finder not responding).
    @discardableResult
    func start(reps: [Rep], rows: Int = 3, cols: Int = 4) async -> Bool {
        guard !reps.isEmpty else { return false }
        stop()
        state = .preparing
        self.reps = reps
        self.completedRepIndex = 0
        self.results = []

        guard let prep = await FinderDrillPrototype.run(rows: rows, cols: cols)
        else {
            state = .idle
            return false
        }
        self.folder = prep.folder
        self.files = prep.files

        let started = observer.start { [weak self] selection in
            self?.selectionDidChange(to: selection)
        }
        guard started else {
            state = .idle
            return false
        }

        startRep()
        return true
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        observer.stop()
        if let folder { FinderDrillPrototype.cleanUp(folder) }
        folder = nil
        files = []
        state = .idle
    }

    // MARK: - Rep machine

    private func startRep() {
        guard let rep = currentRep else {
            completeDrill()
            return
        }
        moveCount = 0
        elapsedTime = 0

        // Self-selecting the start file will fire the observer once.
        // We want to skip that as a "move", so set currentSelection
        // BEFORE the selection lands — the dedup check will absorb it.
        currentSelection = rep.start
        _ = FinderGrid.selectFile(named: rep.start)

        state = .active
        startTime = Date()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let t = self.startTime, self.state == .active else { return }
                self.elapsedTime = Date().timeIntervalSince(t)
            }
        }
        AppLogger.shared.info("finderDrill", "repStart", fields: [
            "index": "\(completedRepIndex)",
            "start": rep.start,
            "target": rep.target
        ])
    }

    private func selectionDidChange(to selection: String?) {
        guard state == .active else { return }
        // Dedupe: same-name fires (observer redundancy) don't count.
        guard let selection, selection != currentSelection else { return }
        currentSelection = selection
        moveCount += 1

        AppLogger.shared.info("finderDrill", "repMove", fields: [
            "index": "\(completedRepIndex)",
            "selection": selection,
            "moves": "\(moveCount)"
        ])

        if selection == currentRep?.target {
            completeRep()
        }
    }

    private func completeRep() {
        guard let rep = currentRep else { return }
        timer?.invalidate()
        timer = nil
        let elapsed = startTime.map { Date().timeIntervalSince($0) } ?? 0
        let result = RepResult(rep: rep, moves: moveCount, timeSeconds: elapsed)
        results.append(result)
        AppLogger.shared.info("finderDrill", "repComplete", fields: [
            "index": "\(completedRepIndex)",
            "moves": "\(moveCount)",
            "time": String(format: "%.2f", elapsed)
        ])
        completedRepIndex += 1
        state = .repCompleted

        // Advance after a short beat so the student sees the hit.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(700))
            startRep()
        }
    }

    private func completeDrill() {
        timer?.invalidate()
        timer = nil
        observer.stop()
        state = .drillCompleted
        let totalMoves = results.reduce(0) { $0 + $1.moves }
        let totalTime = results.reduce(0) { $0 + $1.timeSeconds }
        AppLogger.shared.info("finderDrill", "drillComplete", fields: [
            "reps": "\(results.count)",
            "moves": "\(totalMoves)",
            "time": String(format: "%.2f", totalTime)
        ])
    }
}
