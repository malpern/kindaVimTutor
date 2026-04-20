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
        /// Waiting for Finder to land on the rep's start file before
        /// we begin counting moves + time. Protects against the
        /// transient observer fires between "we asked to select the
        /// start" and "Finder actually shows the start selected".
        case seeding
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
    /// Human-readable goal of this drill, shown at the top of the
    /// coaching panel so the student always has context.
    private(set) var title: String = "Finder Navigation"
    private(set) var subtitle: String = "Move the selection to each red file using h j k l"
    private(set) var completedRepIndex: Int = 0
    private(set) var moveCount: Int = 0
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var results: [RepResult] = []
    /// The selection we've most recently observed. Used to dedupe the
    /// AXObserver's 2–3x redundant fires per real change, and as the
    /// pre-state so rep-start self-selection isn't scored as a move.
    private(set) var currentSelection: String?

    /// Called once when the drill transitions to `.drillCompleted`.
    /// Lets callers run wrap-up UX (close Finder windows, fire
    /// confetti, return focus to the tutor) without the engine having
    /// to know about any of it.
    var onDrillCompleted: (() -> Void)?

    private let observer = FinderSelectionObserver()
    private var startTime: Date?
    private var timer: Timer?
    private var files: [URL] = []
    private var previousTargetURL: URL?

    var currentRep: Rep? {
        guard completedRepIndex < reps.count else { return nil }
        return reps[completedRepIndex]
    }

    // MARK: - Lifecycle

    /// Starts a drill: materialize tmp folder, open Finder, install
    /// the AX observer, run reps sequentially. Returns false if the
    /// setup fails (e.g. AX not trusted or Finder not responding).
    @discardableResult
    func start(reps: [Rep],
               title: String = "Finder Navigation",
               subtitle: String = "Move the selection to each red file using h j k l",
               rows: Int = 3,
               cols: Int = 4) async -> Bool {
        guard !reps.isEmpty else { return false }
        stop()
        state = .preparing
        self.reps = reps
        self.title = title
        self.subtitle = subtitle
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

        // Move the red tag to the current target so the visual cue in
        // Finder always matches the goal in the coaching panel.
        if let folder {
            if let prev = previousTargetURL {
                FinderDrillPrototype.tagURL(prev, with: nil)
            }
            let targetURL = folder.appendingPathComponent(rep.target)
            FinderDrillPrototype.tagURL(targetURL, with: "Red")
            previousTargetURL = targetURL
        }

        // Kick off selection, then wait for it to actually land before
        // starting the timer + move counting. Avoids counting the
        // transition from whatever-was-selected-before into the
        // start file as a "move".
        state = .seeding
        _ = FinderGrid.selectFile(named: rep.start)
        AppLogger.shared.info("finderDrill", "repStart", fields: [
            "index": "\(completedRepIndex)",
            "start": rep.start,
            "target": rep.target
        ])
        // If Finder already has the start selected (previous rep's
        // target happened to match), the observer won't fire and
        // we'd be stuck in .seeding. Check now and advance.
        if FinderDrillPrototype.readFinderSelection() == rep.start {
            currentSelection = rep.start
            activateRep()
        }
    }

    /// Called when we observe the student actually at the start file.
    /// Transitions the rep from `.seeding` into `.active` and starts
    /// the clock.
    private func activateRep() {
        state = .active
        startTime = Date()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let t = self.startTime, self.state == .active else { return }
                self.elapsedTime = Date().timeIntervalSince(t)
            }
        }
    }

    private func selectionDidChange(to selection: String?) {
        guard let selection else { return }
        // Seeding: swallow everything until we land on the start file,
        // then flip to active without recording any move.
        if state == .seeding {
            currentSelection = selection
            if let rep = currentRep, selection == rep.start {
                activateRep()
            }
            return
        }
        guard state == .active else { return }
        // Dedupe: same-name fires (observer redundancy) don't count.
        guard selection != currentSelection else { return }
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
        onDrillCompleted?()
    }

    /// Aggregate across all completed reps — for the ring progress +
    /// metrics readouts in the coaching panel (matches the tutor's
    /// left-rail DrillSidebarSection).
    var totalMoves: Int { results.reduce(0) { $0 + $1.moves } }
    var totalTime: TimeInterval { results.reduce(0) { $0 + $1.timeSeconds } }
    var drillProgress: Double {
        guard !reps.isEmpty else { return 0 }
        return Double(completedRepIndex) / Double(reps.count)
    }

    /// The grid delta from the student's current selection to the
    /// target, in (rightward, downward) cells. Positive dx = press l,
    /// negative dx = press h; positive dy = press j, negative dy =
    /// press k. Nil if we can't resolve either cell in Finder's AX
    /// tree (window not frontmost, etc.).
    var directionToTarget: (dx: Int, dy: Int)? {
        guard let rep = currentRep,
              let selection = currentSelection,
              let layout = FinderGrid.readLayout(),
              let from = layout.cell(named: selection),
              let to = layout.cell(named: rep.target) else { return nil }
        return (to.col - from.col, to.row - from.row)
    }
}
