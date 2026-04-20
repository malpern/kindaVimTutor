import SwiftUI
import AppKit

@Observable
@MainActor
final class ExerciseEngine {
    enum State: Equatable {
        case idle
        case active
        case repCompleted
        case drillCompleted
    }

    private(set) var state: State = .idle
    private(set) var exercise: Exercise?

    // Current rep
    private(set) var keystrokeCount: Int = 0
    private(set) var elapsedTime: TimeInterval = 0

    // Drill progress
    private(set) var completedReps: Int = 0
    private(set) var drillCount: Int = 5
    private(set) var totalTime: TimeInterval = 0
    private(set) var totalKeystrokes: Int = 0

    /// Keystrokes + time from the MOST RECENTLY completed rep. These
    /// persist after drill completion so the coaching panel has
    /// something meaningful to show even though `keystrokeCount` +
    /// `elapsedTime` above refer to the "current" rep which is
    /// semantically nonexistent once the drill is done.
    private(set) var lastRepKeystrokes: Int = 0
    private(set) var lastRepTime: TimeInterval = 0

    // Current variation
    private(set) var currentVariation: Exercise.Variation?

    // Session recording
    private(set) var currentSession: DrillSession?

    // Bumps whenever a reset should force the editor to redraw its content,
    // even if the target initialText string is identical to what was last set.
    private(set) var resetNonce: Int = 0

    private var startTime: Date?
    private var drillStartTime: Date?
    private var timer: Timer?
    private var keyMonitor: Any?

    // Fallback keystroke accounting for when kindaVim consumes a
    // keypress globally (via CGEventTap / AX) and synthesizes the
    // cursor/text mutation directly — in that case no NSEvent reaches
    // the app's local monitor, so the NSEvent-based counter misses it.
    // We reconstruct the missing keystroke from the observed editor
    // state change: if text+cursor changed but keystrokeCount didn't
    // grow since the last change, count one.
    private var lastObservedText: String?
    private var lastObservedCursor: Int?
    private var keystrokesAtLastChange: Int = 0

    var isDrillComplete: Bool { state == .drillCompleted }
    var isRepCompleted: Bool { state == .repCompleted }
    var isActive: Bool { state == .active }

    var drillProgress: Double {
        guard drillCount > 0 else { return 0 }
        return Double(completedReps) / Double(drillCount)
    }

    func start(_ exercise: Exercise) {
        self.exercise = exercise
        self.drillCount = exercise.drillCount
        completedReps = 0
        totalTime = 0
        totalKeystrokes = 0
        drillStartTime = Date()

        // Start a new recording session
        currentSession = DrillSession(exerciseId: exercise.id, drillCount: exercise.drillCount)

        AppLogger.shared.info("drill", "start", fields: [
            "exercise": exercise.id,
            "reps": String(exercise.drillCount)
        ])

        installKeyMonitor()
        startRep(exercise.variation(for: 0))
    }

    func resetDrill() {
        guard let exercise else { return }
        resetNonce &+= 1
        start(exercise)
    }

    func resetRep() {
        guard let exercise else { return }
        resetNonce &+= 1
        recordEvent(.repReset, text: currentVariation?.initialText ?? "", cursorPosition: 0)
        startRep(exercise.variation(for: completedReps))
    }

    func textDidChange(currentText: String, cursorPosition: Int) {
        guard state == .active else { return }
        recordEvent(.textChanged, text: currentText, cursorPosition: cursorPosition)
        reconcileKeystroke(text: currentText, cursor: cursorPosition)
        validate(currentText: currentText, cursorPosition: cursorPosition)
    }

    func selectionDidChange(currentText: String, cursorPosition: Int) {
        guard state == .active, currentVariation != nil else { return }
        recordEvent(.cursorMoved, text: currentText, cursorPosition: cursorPosition)
        reconcileKeystroke(text: currentText, cursor: cursorPosition)
        validate(currentText: currentText, cursorPosition: cursorPosition)
    }

    /// If the editor state changed but no NSEvent-backed keystroke
    /// was recorded for it (kindaVim swallowed the key globally),
    /// credit the student with one.
    private func reconcileKeystroke(text: String, cursor: Int) {
        defer {
            lastObservedText = text
            lastObservedCursor = cursor
            keystrokesAtLastChange = keystrokeCount
        }
        guard lastObservedText != nil else { return } // seeded, no prior state
        let changed = text != lastObservedText || cursor != lastObservedCursor
        guard changed else { return }
        if keystrokeCount == keystrokesAtLastChange {
            keystrokeCount += 1
        }
    }

    /// Increment the keystroke counter for the current rep. Called
    /// from the NSEvent monitor on real key presses, and from tests
    /// to simulate them. No-op unless a rep is active.
    func recordKeystroke() {
        guard state == .active else { return }
        keystrokeCount += 1
    }

    func stop() {
        removeKeyMonitor()
        timer?.invalidate()
        timer = nil
        state = .idle
        exercise = nil
        currentVariation = nil
    }

    // MARK: - Key monitor

    private func installKeyMonitor() {
        removeKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Ignore command / option-modified keys — Cmd+Q, Cmd+],
            // etc. aren't the student's drill keystrokes.
            if event.modifierFlags.contains(.command)
                || event.modifierFlags.contains(.option) {
                return event
            }
            // Local NSEvent monitors fire synchronously on the main
            // thread. Increment inline — queuing through `Task { @MainActor }`
            // lets the rep's own validation complete first (flipping
            // state off `.active`), and the deferred count is dropped.
            MainActor.assumeIsolated {
                self?.recordKeystroke()
            }
            return event
        }
    }

    private func removeKeyMonitor() {
        if let m = keyMonitor {
            NSEvent.removeMonitor(m)
            keyMonitor = nil
        }
    }

    // MARK: - Last-rep target (for coaching panel)

    /// The chapter target for the variation the student most recently
    /// played. Variation-level target wins; falls back to the
    /// exercise-level default. nil when neither is tagged.
    var lastRepTarget: Int? {
        currentVariation?.optimalKeystrokes
    }

    // MARK: - Recording

    private func recordEvent(_ type: DrillSession.Event.EventType, text: String, cursorPosition: Int) {
        guard let drillStartTime else { return }
        let timestamp = Date().timeIntervalSince(drillStartTime)
        let event = DrillSession.Event(
            timestamp: timestamp,
            type: type,
            text: text,
            cursorPosition: cursorPosition,
            repIndex: completedReps
        )
        currentSession?.events.append(event)
    }

    // MARK: - Private

    private func startRep(_ variation: Exercise.Variation) {
        currentVariation = variation
        state = .active
        keystrokeCount = 0
        elapsedTime = 0
        startTime = Date()
        lastObservedText = variation.initialText
        lastObservedCursor = variation.initialCursorPosition
        keystrokesAtLastChange = 0

        let repTimestamp = drillStartTime.map { Date().timeIntervalSince($0) } ?? 0

        // Record rep start
        currentSession?.reps.append(DrillSession.RepRecord(
            repIndex: completedReps,
            variationText: variation.initialText,
            expectedText: variation.expectedText,
            expectedCursorPosition: variation.expectedCursorPosition,
            startTimestamp: repTimestamp,
            keystrokeCount: 0,
            completed: false
        ))
        recordEvent(.repStarted, text: variation.initialText, cursorPosition: variation.initialCursorPosition)

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let startTime = self.startTime, self.state == .active else { return }
                self.elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
    }

    private func validate(currentText: String, cursorPosition: Int) {
        guard let variation = currentVariation else { return }

        let textMatches = currentText == variation.expectedText
        let cursorMatches: Bool
        if let expectedCursor = variation.expectedCursorPosition {
            cursorMatches = cursorPosition == expectedCursor
        } else {
            cursorMatches = true
        }

        if textMatches && cursorMatches {
            completeRep(finalText: currentText, finalCursor: cursorPosition)
        }
    }

    private func completeRep(finalText: String, finalCursor: Int) {
        timer?.invalidate()
        timer = nil

        let repTime = startTime.map { Date().timeIntervalSince($0) } ?? 0
        totalTime += repTime
        totalKeystrokes += keystrokeCount

        // Snapshot for the coaching panel — these survive past
        // drill completion when the per-rep counters get zeroed or
        // become meaningless.
        lastRepKeystrokes = keystrokeCount
        lastRepTime = repTime

        // Update rep record
        let repTimestamp = drillStartTime.map { Date().timeIntervalSince($0) } ?? 0
        if let session = currentSession, let lastIndex = session.reps.indices.last {
            var lastRep = session.reps[lastIndex]
            lastRep.endTimestamp = repTimestamp
            lastRep.keystrokeCount = keystrokeCount
            lastRep.completed = true
            currentSession?.reps[lastIndex] = lastRep
        }

        recordEvent(.repCompleted, text: finalText, cursorPosition: finalCursor)
        completedReps += 1

        AppLogger.shared.info("drill", "repCompleted", fields: [
            "exercise": exercise?.id ?? "",
            "rep": String(completedReps),
            "of": String(drillCount),
            "keystrokes": String(keystrokeCount),
            "time": String(format: "%.3f", repTime)
        ])

        if completedReps >= drillCount {
            state = .drillCompleted
            recordEvent(.drillCompleted, text: finalText, cursorPosition: finalCursor)
            currentSession?.completedAt = Date()
            AppLogger.shared.info("drill", "completed", fields: [
                "exercise": exercise?.id ?? "",
                "totalKeystrokes": String(totalKeystrokes),
                "totalTime": String(format: "%.3f", totalTime)
            ])
        } else {
            state = .repCompleted
            guard let exercise else { return }
            let nextVariation = exercise.variation(for: completedReps)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                guard let self, self.state == .repCompleted else { return }
                self.startRep(nextVariation)
            }
        }
    }
}
