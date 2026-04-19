import SwiftUI

/// Two stacked looping demos that frame the modes concept in the way
/// a new Mac user thinks about it: "this is how text fields normally
/// work" followed by "but with kindaVim, you can…". Each panel runs
/// independently on its own timer; tap either panel to replay it from
/// frame 0.
///
/// Deliberately does NOT render a mode chip inside either panel —
/// kindaVim doesn't embed chips into text fields, and showing one
/// would misrepresent how it actually works. The caret shape (thin
/// line vs solid block) carries the mode cue, which is how Vim has
/// signaled it for decades.
struct ModesDemoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            DemoPanel(
                phase: .macDefault,
                intro: "How Mac text fields normally work",
                script: Self.macDefaultScript
            )
            DemoPanel(
                phase: .withKindaVim,
                intro: "With kindaVim, press `Esc` and keys become commands",
                script: Self.withKindaVimScript
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Scripts

    /// Mac-default demo: start empty, type "hi there", linger, loop.
    /// Caret is always a thin line. No Esc, no commands — this is the
    /// behavior every Mac user already knows.
    static let macDefaultScript: [Beat] = [
        Beat(text: "",        caret: 0, mode: .insert, pressedKey: nil,    caption: "Click in, type, letters appear. That's it.", duration: 1.6),
        Beat(text: "h",       caret: 1, mode: .insert, pressedKey: "h",    caption: nil,                                           duration: 0.28),
        Beat(text: "hi",      caret: 2, mode: .insert, pressedKey: "i",    caption: nil,                                           duration: 0.28),
        Beat(text: "hi ",     caret: 3, mode: .insert, pressedKey: "Space",caption: nil,                                           duration: 0.20),
        Beat(text: "hi t",    caret: 4, mode: .insert, pressedKey: "t",    caption: nil,                                           duration: 0.22),
        Beat(text: "hi th",   caret: 5, mode: .insert, pressedKey: "h",    caption: nil,                                           duration: 0.22),
        Beat(text: "hi the",  caret: 6, mode: .insert, pressedKey: "e",    caption: nil,                                           duration: 0.22),
        Beat(text: "hi ther", caret: 7, mode: .insert, pressedKey: "r",    caption: nil,                                           duration: 0.22),
        Beat(text: "hi there",caret: 8, mode: .insert, pressedKey: "e",    caption: "Every key → a letter.",                       duration: 2.0),
    ]

    /// kindaVim demo: start with the same "hi there", press Esc to
    /// enter Normal, walk the caret left, delete chars, wipe line,
    /// press i, retype "done". Caret morphs between thin-line (Insert)
    /// and solid-block (Normal) as Vim itself does.
    static let withKindaVimScript: [Beat] = [
        Beat(text: "hi there",caret: 8, mode: .insert, pressedKey: nil,    caption: "Start in the normal Mac way — typing mode.",    duration: 1.4),
        Beat(text: "hi there",caret: 8, mode: .normal, pressedKey: "Esc",  caption: "Press Esc. Caret flips — keys are now commands.", duration: 1.8),
        Beat(text: "hi there",caret: 7, mode: .normal, pressedKey: "h",    caption: "h moves the cursor left.",                      duration: 0.7),
        Beat(text: "hi there",caret: 6, mode: .normal, pressedKey: "h",    caption: nil,                                             duration: 0.35),
        Beat(text: "hi there",caret: 5, mode: .normal, pressedKey: "h",    caption: nil,                                             duration: 0.35),
        Beat(text: "hi ther", caret: 5, mode: .normal, pressedKey: "x",    caption: "x deletes a character.",                        duration: 0.8),
        Beat(text: "hi the",  caret: 5, mode: .normal, pressedKey: "x",    caption: nil,                                             duration: 0.4),
        Beat(text: "hi th",   caret: 5, mode: .normal, pressedKey: "x",    caption: nil,                                             duration: 0.4),
        Beat(text: "",        caret: 0, mode: .normal, pressedKey: "dd",   caption: "dd wipes the whole line.",                      duration: 1.6),
        Beat(text: "",        caret: 0, mode: .insert, pressedKey: "i",    caption: "Press i. Back to typing.",                      duration: 1.2),
        Beat(text: "d",       caret: 1, mode: .insert, pressedKey: "d",    caption: nil,                                             duration: 0.22),
        Beat(text: "do",      caret: 2, mode: .insert, pressedKey: "o",    caption: nil,                                             duration: 0.22),
        Beat(text: "don",     caret: 3, mode: .insert, pressedKey: "n",    caption: nil,                                             duration: 0.22),
        Beat(text: "done",    caret: 4, mode: .insert, pressedKey: "e",    caption: "Same keyboard. Two jobs.",                      duration: 2.4),
    ]
}

// MARK: - Beat

extension ModesDemoView {
    struct Beat {
        let text: String
        let caret: Int
        let mode: VimMode
        let pressedKey: String?
        let caption: String?
        let duration: TimeInterval
    }
}

// MARK: - Demo panel

private enum DemoPhase { case macDefault, withKindaVim }

private struct DemoPanel: View {
    let phase: DemoPhase
    let intro: String
    let script: [ModesDemoView.Beat]

    @State private var beatIndex: Int = 0
    @State private var timer: Timer?
    @State private var caretVisible: Bool = true
    @State private var cursorTimer: Timer?

    private var beat: ModesDemoView.Beat { script[beatIndex] }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Intro framing — the sentence that names what this panel
            // demonstrates.
            AnnotatedText(string: intro,
                          font: .system(size: 14, weight: .medium),
                          capSize: .small,
                          foregroundStyle: .secondary)

            documentPanel
            captionRow
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.22))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.18), lineWidth: 0.75)
        }
        .contentShape(Rectangle())
        .onTapGesture { restart() }
        .help("Tap to replay")
        .onAppear {
            start()
            startCaretBlink()
        }
        .onDisappear {
            timer?.invalidate(); timer = nil
            cursorTimer?.invalidate(); cursorTimer = nil
        }
    }

    private var documentPanel: some View {
        HStack(spacing: 0) {
            Text(beat.text.prefix(beat.caret))
                .font(.system(size: 22, weight: .regular, design: .monospaced))
                .foregroundStyle(.primary)
            CaretView(mode: beat.mode, visible: caretVisible)
                .padding(.horizontal, 0.5)
            Text(beat.text.dropFirst(beat.caret))
                .font(.system(size: 22, weight: .regular, design: .monospaced))
                .foregroundStyle(.primary)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.black.opacity(0.30))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.18), lineWidth: 0.75)
        }
        .animation(.easeOut(duration: 0.12), value: beat.text)
        .animation(.easeOut(duration: 0.15), value: beat.caret)
    }

    private var captionRow: some View {
        HStack(spacing: 12) {
            if let keyLabel = beat.pressedKey {
                PressedKeyChip(label: keyLabel)
                    .id("key-\(beatIndex)")
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            } else {
                // Keep the caption column stable when no key is active
                // so text doesn't jitter horizontally between beats.
                Color.clear.frame(width: 40, height: 30)
            }

            Text(beat.caption ?? "")
                .font(.system(size: 14, weight: .regular))
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
        timer = Timer.scheduledTimer(withTimeInterval: beat.duration, repeats: false) { _ in
            Task { @MainActor in
                beatIndex = (beatIndex + 1) % script.count
                scheduleNext()
            }
        }
    }

    private func restart() {
        timer?.invalidate()
        beatIndex = 0
        scheduleNext()
    }

    private func startCaretBlink() {
        cursorTimer = Timer.scheduledTimer(withTimeInterval: 0.53, repeats: true) { _ in
            Task { @MainActor in caretVisible.toggle() }
        }
    }
}

// MARK: - Parts

private struct CaretView: View {
    let mode: VimMode
    let visible: Bool

    var body: some View {
        // Thin line caret in Insert (typing), solid block in Normal
        // (commands). This is how terminal Vim and kindaVim both cue
        // the current mode at the cursor itself.
        Rectangle()
            .fill(mode == .insert ? Color.accentColor : Color.primary.opacity(0.85))
            .frame(width: mode == .insert ? 2 : 13, height: 26)
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
