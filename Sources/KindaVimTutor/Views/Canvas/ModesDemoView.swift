import SwiftUI

/// Single-panel, single-timeline demonstration of Normal vs Insert.
///
/// Shape of the page:
///
///   INSERT MODE    ← big named state label (narrator chrome, not UI)
///   Letters type.
///   ┌────────────────────────────────┐
///   │  hi there|                     │ ← scripted text field
///   └────────────────────────────────┘
///   [h]  Every key → a letter.        ← pressed-key chip + caption
///
/// One continuous script takes the student from Insert → Esc →
/// Normal (h / x / dd) → i → Insert, with the mode label flipping
/// BEFORE the behavior changes so the vocabulary lands ahead of the
/// visual. Tap to replay. Obeys AnimationReplayTracker so back-nav
/// doesn't re-play.
struct ModesDemoView: View {
    private static let animationID = "modesDemo.ch1.l0"

    @State private var beatIndex: Int = 0
    @State private var timer: Timer?
    @State private var caretVisible: Bool = true
    @State private var cursorTimer: Timer?
    @State private var didComplete: Bool = false

    private var beat: Beat { Self.script[min(beatIndex, Self.script.count - 1)] }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Named mode supralabel — the page's anchor. Flips color
            // and text with the beat, always visible.
            ModeStateLabel(mode: beat.mode, caption: beat.modeCaption)
                .animation(.easeOut(duration: 0.25), value: beat.mode)

            documentField
            actionLine
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.22))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.20), lineWidth: 0.75)
        }
        .contentShape(Rectangle())
        .onTapGesture { restart() }
        .help("Tap to replay")
        .onAppear {
            startCaretBlink()
            if AnimationReplayTracker.shared.hasPlayed(Self.animationID) {
                // Already seen — park on the final beat, no playback.
                beatIndex = Self.script.count - 1
                didComplete = true
                return
            }
            AnimationReplayTracker.shared.markPlayed(Self.animationID)
            start()
        }
        .onDisappear {
            timer?.invalidate(); timer = nil
            cursorTimer?.invalidate(); cursorTimer = nil
        }
    }

    // MARK: - Subviews

    private var documentField: some View {
        HStack(spacing: 0) {
            Text(beat.text.prefix(beat.caret))
                .font(.system(size: 24, weight: .regular, design: .monospaced))
                .foregroundStyle(.primary)
            CaretView(mode: beat.mode, visible: caretVisible)
                .padding(.horizontal, 0.5)
            Text(beat.text.dropFirst(beat.caret))
                .font(.system(size: 24, weight: .regular, design: .monospaced))
                .foregroundStyle(.primary)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.30))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.18), lineWidth: 0.75)
        }
        .animation(.easeOut(duration: 0.12), value: beat.text)
        .animation(.easeOut(duration: 0.15), value: beat.caret)
    }

    private var actionLine: some View {
        HStack(spacing: 12) {
            if let key = beat.pressedKey {
                HStack(spacing: 6) {
                    PressedKeyChip(label: key)
                    if beat.isCommandPress {
                        // Tells the student "this key did something,
                        // but not the typing thing you're used to"
                        // — defuses the "wait, nothing happened"
                        // confusion without teaching the specific
                        // command yet.
                        Text("(command)")
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(.tertiary)
                            .transition(.opacity)
                    }
                }
                .id("key-\(beatIndex)")
                .transition(.scale(scale: 0.6).combined(with: .opacity))
            } else {
                Color.clear.frame(width: 40, height: 30)
            }

            Text(beat.caption ?? "")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.secondary)
                .animation(.easeOut(duration: 0.2), value: beat.caption)

            Spacer()
        }
        .frame(height: 32)
        .animation(.easeInOut(duration: 0.15), value: beatIndex)
    }

    // MARK: - Playback

    private func start() { scheduleNext() }

    private func scheduleNext() {
        timer?.invalidate()
        let hold = beat.duration
        timer = Timer.scheduledTimer(withTimeInterval: hold, repeats: false) { _ in
            Task { @MainActor in
                if beatIndex + 1 >= Self.script.count {
                    // Completed — park on the final frame, no loop.
                    // User can tap to replay.
                    didComplete = true
                    return
                }
                beatIndex += 1
                scheduleNext()
            }
        }
    }

    private func restart() {
        timer?.invalidate()
        didComplete = false
        beatIndex = 0
        scheduleNext()
    }

    private func startCaretBlink() {
        cursorTimer = Timer.scheduledTimer(withTimeInterval: 0.53, repeats: true) { _ in
            Task { @MainActor in caretVisible.toggle() }
        }
    }

    // MARK: - Beat model

    struct Beat {
        let text: String
        let caret: Int
        let mode: VimMode
        let modeCaption: String
        let pressedKey: String?
        /// When true, the key chip gets a muted "(command)" tag next to
        /// it. Use on Normal-mode letter presses that don't produce
        /// text, so the "nothing happened" reads as intentional rather
        /// than a broken demo.
        let isCommandPress: Bool
        let caption: String?
        let duration: TimeInterval

        init(text: String, caret: Int, mode: VimMode, modeCaption: String,
             pressedKey: String?, isCommandPress: Bool = false,
             caption: String?, duration: TimeInterval) {
            self.text = text; self.caret = caret; self.mode = mode
            self.modeCaption = modeCaption
            self.pressedKey = pressedKey
            self.isCommandPress = isCommandPress
            self.caption = caption; self.duration = duration
        }
    }

    /// Simplified pedagogy: show that typing works in Insert, stops in
    /// Normal, and resumes in Insert again. No h/x/dd — those teach
    /// specific commands the student doesn't know yet and would make
    /// the demo compete with itself.
    static let script: [Beat] = [
        // ── 1. Insert mode: typing works ─────────────────────────
        Beat(text: "",         caret: 0, mode: .insert,
             modeCaption: "Every key becomes a letter.",
             pressedKey: nil,  caption: "Click in and type — like any Mac text field.", duration: 1.4),
        Beat(text: "h",        caret: 1, mode: .insert,
             modeCaption: "Every key becomes a letter.",
             pressedKey: "h",  caption: nil,  duration: 0.26),
        Beat(text: "hi",       caret: 2, mode: .insert,
             modeCaption: "Every key becomes a letter.",
             pressedKey: "i",  caption: nil,  duration: 0.26),
        Beat(text: "hi ",      caret: 3, mode: .insert,
             modeCaption: "Every key becomes a letter.",
             pressedKey: "Space", caption: nil,  duration: 0.18),
        Beat(text: "hi t",     caret: 4, mode: .insert,
             modeCaption: "Every key becomes a letter.",
             pressedKey: "t",  caption: nil,  duration: 0.20),
        Beat(text: "hi th",    caret: 5, mode: .insert,
             modeCaption: "Every key becomes a letter.",
             pressedKey: "h",  caption: nil,  duration: 0.20),
        Beat(text: "hi the",   caret: 6, mode: .insert,
             modeCaption: "Every key becomes a letter.",
             pressedKey: "e",  caption: nil,  duration: 0.20),
        Beat(text: "hi ther",  caret: 7, mode: .insert,
             modeCaption: "Every key becomes a letter.",
             pressedKey: "r",  caption: nil,  duration: 0.20),
        Beat(text: "hi there", caret: 8, mode: .insert,
             modeCaption: "Every key becomes a letter.",
             pressedKey: "e",  caption: "Typing works the way you'd expect.", duration: 1.4),

        // ── 2. Switch to Normal ──────────────────────────────────
        Beat(text: "hi there", caret: 8, mode: .normal,
             modeCaption: "Typing is paused. Keys do other jobs now.",
             pressedKey: "Esc", caption: "Press Esc. Caret thickens — typing stops.", duration: 1.9),

        // ── 3. Normal mode: letter keys don't type ───────────────
        Beat(text: "hi there", caret: 8, mode: .normal,
             modeCaption: "Typing is paused. Keys do other jobs now.",
             pressedKey: "h",  isCommandPress: true,
             caption: "Press a letter — nothing types.",               duration: 1.2),
        Beat(text: "hi there", caret: 8, mode: .normal,
             modeCaption: "Typing is paused. Keys do other jobs now.",
             pressedKey: "a",  isCommandPress: true,
             caption: nil,                                             duration: 0.65),
        Beat(text: "hi there", caret: 8, mode: .normal,
             modeCaption: "Typing is paused. Keys do other jobs now.",
             pressedKey: "x",  isCommandPress: true,
             caption: "Each one runs a command. You'll learn them next.", duration: 2.0),

        // ── 4. Switch back to Insert ─────────────────────────────
        Beat(text: "hi there", caret: 8, mode: .insert,
             modeCaption: "Every key becomes a letter.",
             pressedKey: "i",  caption: "Press i. Caret thins — typing resumes.", duration: 1.4),

        // ── 5. Insert mode again: typing works ───────────────────
        Beat(text: "hi there ",     caret: 9,  mode: .insert,
             modeCaption: "Every key becomes a letter.",
             pressedKey: "Space",  caption: nil,  duration: 0.20),
        Beat(text: "hi there d",    caret: 10, mode: .insert,
             modeCaption: "Every key becomes a letter.",
             pressedKey: "d",      caption: nil,  duration: 0.20),
        Beat(text: "hi there do",   caret: 11, mode: .insert,
             modeCaption: "Every key becomes a letter.",
             pressedKey: "o",      caption: nil,  duration: 0.20),
        Beat(text: "hi there don",  caret: 12, mode: .insert,
             modeCaption: "Every key becomes a letter.",
             pressedKey: "n",      caption: nil,  duration: 0.20),
        Beat(text: "hi there done", caret: 13, mode: .insert,
             modeCaption: "Every key becomes a letter.",
             pressedKey: "e",      caption: "Same keyboard. Two modes.", duration: 2.2),
    ]
}

// MARK: - Mode state label (big supralabel)

/// Narrator chrome — a page-level label that names the current mode.
/// Styled as typographic caption, not a chip, to avoid implying kV
/// embeds this into text fields.
private struct ModeStateLabel: View {
    let mode: VimMode
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Circle()
                    .fill(mode.color)
                    .frame(width: 9, height: 9)
                Text("\(mode.displayName) MODE")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .tracking(1.5)
                    .contentTransition(.numericText())
            }
            Text(caption)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.secondary)
                .animation(.easeOut(duration: 0.2), value: caption)
        }
    }
}

// MARK: - Parts

private struct CaretView: View {
    let mode: VimMode
    let visible: Bool

    var body: some View {
        Rectangle()
            .fill(mode == .insert ? Color.accentColor : Color.primary.opacity(0.85))
            .frame(width: mode == .insert ? 2 : 14, height: 28)
            .opacity(visible ? 1 : 0.1)
            .animation(.easeInOut(duration: 0.12), value: mode)
    }
}

private struct PressedKeyChip: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.primary)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .frame(minWidth: 36)
            .background {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.accentColor.opacity(0.25))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(Color.accentColor.opacity(0.55), lineWidth: 0.75)
            }
    }
}
