import AppKit
import Foundation
import Observation

/// Drives an "in the wild" text-editing drill in a system app. Sibling
/// to `FinderDrillEngine`, with the same state machine shape and the
/// same coaching-panel contract, but works on text mutations instead
/// of Finder selection.
///
/// Per-rep completion is expressed in the authoring spec as a
/// `CompletionPredicate`. The engine observes text + selection via
/// `ExternalTextObserver` (AXObserver under the hood) and re-evaluates
/// the current rep's predicate on every change.
@Observable
@MainActor
final class ExternalTextDrillEngine {
    enum State: Equatable {
        case idle
        case preparing
        case active
        case repCompleted
        case drillCompleted
    }

    enum StartError: Error {
        case usabilityFailed(reason: String)
        case surfacePreparationFailed
    }

    struct RepResult: Equatable {
        let predicate: CompletionPredicate
        let timeSeconds: TimeInterval
        let keystrokes: Int
    }

    let surface: ExternalTextSurface
    let spec: ExternalTextDrillSpec

    private(set) var state: State = .idle
    private(set) var completedRepIndex: Int = 0
    private(set) var results: [RepResult] = []
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var latestText: String = ""
    /// Flips true the first time we receive a non-nil observation.
    /// Until then, the engine ignores `nil` reads ("AX couldn't
    /// find the text area yet") — otherwise an unresolved initial
    /// read would coerce to "" and fire empty-text completions
    /// before the student does anything.
    private(set) var hasReceivedText: Bool = false

    /// Fires once when all reps are complete. Callers (views / the
    /// panel) use this to trigger cleanup + celebration.
    var onDrillCompleted: (() -> Void)?

    private var prepared: PreparedSurface?
    private let observer = ExternalTextObserver()
    private var startTime: Date?
    private var timer: Timer?
    /// Per-rep key count. Reset at each rep boundary and copied into
    /// RepResult on completion. Total across the drill is the sum of
    /// result keystrokes.
    private var currentRepKeystrokes: Int = 0
    private var keydownMonitor: Any?

    var totalKeystrokes: Int {
        results.reduce(0) { $0 + $1.keystrokes } + currentRepKeystrokes
    }

    init(surface: ExternalTextSurface, spec: ExternalTextDrillSpec) {
        self.surface = surface
        self.spec = spec
    }

    // MARK: - Lifecycle

    /// Materialise the surface (create note / compose draft),
    /// install the AX observer, begin the first rep. Throws if the
    /// surface can't be prepared — caller surfaces a message.
    func start() async throws {
        stop()
        state = .preparing

        let usability = await surface.isUsable()
        if case .needsSetup(let reason) = usability {
            state = .idle
            throw StartError.usabilityFailed(reason: reason)
        }

        do {
            let prepared = try await surface.prepare(body: spec.seedBody)
            self.prepared = prepared
        } catch {
            state = .idle
            throw StartError.surfacePreparationFailed
        }

        guard let prepared else {
            state = .idle
            throw StartError.surfacePreparationFailed
        }

        observer.start(
            bundleIdentifier: prepared.bundleIdentifier
        ) { [weak self] text in
            self?.textDidChange(to: text)
        }

        completedRepIndex = 0
        results = []
        latestText = spec.seedBody
        hasReceivedText = false
        currentRepKeystrokes = 0
        installKeydownMonitor()
        activateRep()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        observer.stop()
        removeKeydownMonitor()
        if let prepared {
            Task { [surface] in await surface.cleanup(prepared) }
        }
        prepared = nil
        // Preserve `.drillCompleted` so a step view showing the
        // summary can survive teardown without flipping back to
        // idle. Any non-completed state is treated as abandoned.
        if state != .drillCompleted {
            state = .idle
        }
    }

    /// Global keydown watcher. Same pattern the coaching view uses to
    /// spot "student is still in insert mode" keystrokes, but here we
    /// just tally them so the completion screen can show a Keys metric.
    /// Keystrokes fire in the target app (Notes), which the tutor
    /// never sees through responder chain — only a global monitor
    /// catches them. Modifier-only keys (Cmd+X, Option+arrow) are
    /// ignored; they're system shortcuts, not drill keystrokes.
    private func installKeydownMonitor() {
        guard keydownMonitor == nil else { return }
        keydownMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: .keyDown
        ) { [weak self] event in
            let flags = event.modifierFlags
            if flags.contains(.command) || flags.contains(.option) { return }
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    guard let self, self.state == .active else { return }
                    self.currentRepKeystrokes += 1
                }
            }
        }
    }

    private func removeKeydownMonitor() {
        if let keydownMonitor {
            NSEvent.removeMonitor(keydownMonitor)
        }
        keydownMonitor = nil
    }

    // MARK: - Per-rep machine

    var currentRep: ExternalTextDrillSpec.Rep? {
        guard completedRepIndex < spec.reps.count else { return nil }
        return spec.reps[completedRepIndex]
    }

    var currentPredicate: CompletionPredicate? { currentRep?.predicate }

    private func activateRep() {
        guard currentRep != nil else {
            completeDrill()
            return
        }
        state = .active
        startTime = Date()
        elapsedTime = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let t = self.startTime, self.state == .active else { return }
                self.elapsedTime = Date().timeIntervalSince(t)
            }
        }
        AppLogger.shared.info("extDrill", "repStart", fields: [
            "index": "\(completedRepIndex)"
        ])
    }

    private func textDidChange(to text: String?) {
        // Ignore reads where AX returned nothing — they'd coerce
        // to "" and falsely satisfy textDoesNotContain predicates
        // before the student did anything.
        guard let text else { return }
        latestText = text
        if !hasReceivedText {
            hasReceivedText = true
            AppLogger.shared.info("extDrill", "textSeeded",
                                  fields: ["length": "\(text.count)"])
        }
        guard state == .active, let predicate = currentPredicate else { return }
        if predicate.evaluate(against: text) {
            completeRep()
        }
    }

    private func completeRep() {
        guard let predicate = currentPredicate else { return }
        timer?.invalidate()
        timer = nil
        let elapsed = startTime.map { Date().timeIntervalSince($0) } ?? 0
        results.append(RepResult(
            predicate: predicate,
            timeSeconds: elapsed,
            keystrokes: currentRepKeystrokes
        ))
        AppLogger.shared.info("extDrill", "repComplete", fields: [
            "index": "\(completedRepIndex)",
            "time": String(format: "%.2f", elapsed),
            "keys": "\(currentRepKeystrokes)"
        ])
        currentRepKeystrokes = 0
        completedRepIndex += 1
        state = .repCompleted
        // Brief beat so the student sees the flash, then the next rep.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(700))
            activateRep()
        }
    }

    private func completeDrill() {
        timer?.invalidate()
        timer = nil
        observer.stop()
        removeKeydownMonitor()
        state = .drillCompleted
        AppLogger.shared.info("extDrill", "drillComplete", fields: [
            "reps": "\(results.count)"
        ])
        // Tear down the surface (delete the drill note / draft)
        // here rather than waiting for a caller to call stop(). A
        // completed drill is "done with" the surface; callers who
        // need to retain the engine for summary rendering don't
        // need the underlying note to still exist.
        if let prepared {
            Task { [surface] in await surface.cleanup(prepared) }
            self.prepared = nil
        }
        onDrillCompleted?()
    }
}

extension CompletionPredicate {
    /// Evaluate this predicate against the currently observed text.
    /// Returns true when the rep should be marked complete.
    func evaluate(against text: String) -> Bool {
        switch self {
        case .textEquals(let target):
            return text == target
        case .textDoesNotContain(let fragment):
            return !text.contains(fragment)
        case .textContains(let fragment):
            return text.contains(fragment)
        }
    }
}
