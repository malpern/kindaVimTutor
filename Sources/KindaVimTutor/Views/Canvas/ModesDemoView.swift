import SwiftUI

/// Show-rather-than-tell demonstration of Insert vs Normal mode.
/// Plays a scripted sequence: the student sees a caret, text appearing
/// letter by letter, an Esc press, the mode chip flipping, then
/// movement commands, deletions, and a return to Insert. Replays on
/// tap. Drops in as a single ContentBlock, no parameters required.
struct ModesDemoView: View {
    @State private var beatIndex: Int = 0
    @State private var timer: Timer?
    @State private var caretVisible: Bool = true
    @State private var cursorTimer: Timer?

    private var beat: Beat { Self.script[beatIndex] }

    var body: some View {
        VStack(spacing: 14) {
            documentPanel
            captionRow
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.25))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.20), lineWidth: 0.75)
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

    // MARK: - Layout

    private var documentPanel: some View {
        HStack(alignment: .center, spacing: 12) {
            // Mode chip — same visual language as the toolbar badge, sized down.
            ModeChip(mode: beat.mode)
                .animation(.easeOut(duration: 0.25), value: beat.mode)

            // Faux document line with caret.
            HStack(spacing: 0) {
                Text(beat.text.prefix(beat.caret))
                    .font(.system(size: 22, weight: .regular, design: .monospaced))
                    .foregroundStyle(.primary)
                CaretView(mode: beat.mode, visible: caretVisible)
                    .padding(.horizontal, 0.5)
                Text(beat.text.dropFirst(beat.caret))
                    .font(.system(size: 22, weight: .regular, design: .monospaced))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(.easeOut(duration: 0.12), value: beat.text)
            .animation(.easeOut(duration: 0.15), value: beat.caret)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.30))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.18), lineWidth: 0.75)
        }
    }

    private var captionRow: some View {
        HStack(spacing: 14) {
            // Pressed key — flashes in on each beat that has one.
            if let keyLabel = beat.pressedKey {
                PressedKeyChip(label: keyLabel)
                    .id("key-\(beatIndex)")
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            } else {
                // Placeholder so the caption doesn't jitter horizontally
                // on beats that have no key.
                Color.clear.frame(width: 40, height: 32)
            }

            Text(beat.caption ?? "")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.secondary)
                .animation(.easeOut(duration: 0.2), value: beat.caption)

            Spacer()
        }
        .frame(height: 34)
        .animation(.easeInOut(duration: 0.15), value: beatIndex)
    }

    // MARK: - Playback

    private func start() {
        scheduleNext()
    }

    private func scheduleNext() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: beat.duration, repeats: false) { _ in
            Task { @MainActor in
                let next = (beatIndex + 1) % Self.script.count
                beatIndex = next
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

    // MARK: - Script

    struct Beat {
        let text: String
        let caret: Int
        let mode: VimMode
        let pressedKey: String?
        let caption: String?
        let duration: TimeInterval
    }

    static let script: [Beat] = [
        Beat(text: "",        caret: 0, mode: .insert, pressedKey: nil,   caption: "Every Mac text field starts in Insert mode. Letters become text.", duration: 1.8),
        Beat(text: "h",       caret: 1, mode: .insert, pressedKey: "h",   caption: nil,                                                                 duration: 0.28),
        Beat(text: "hi",      caret: 2, mode: .insert, pressedKey: "i",   caption: nil,                                                                 duration: 0.28),
        Beat(text: "hi ",     caret: 3, mode: .insert, pressedKey: "Space", caption: nil,                                                              duration: 0.20),
        Beat(text: "hi t",    caret: 4, mode: .insert, pressedKey: "t",   caption: nil,                                                                 duration: 0.22),
        Beat(text: "hi th",   caret: 5, mode: .insert, pressedKey: "h",   caption: nil,                                                                 duration: 0.22),
        Beat(text: "hi the",  caret: 6, mode: .insert, pressedKey: "e",   caption: nil,                                                                 duration: 0.22),
        Beat(text: "hi ther", caret: 7, mode: .insert, pressedKey: "r",   caption: nil,                                                                 duration: 0.22),
        Beat(text: "hi there",caret: 8, mode: .insert, pressedKey: "e",   caption: "Every key → a letter.",                                             duration: 1.6),
        Beat(text: "hi there",caret: 8, mode: .normal, pressedKey: "Esc", caption: "Press Esc. Now the same keys become commands.",                     duration: 1.8),
        Beat(text: "hi there",caret: 7, mode: .normal, pressedKey: "h",   caption: "h moves the cursor left.",                                          duration: 0.7),
        Beat(text: "hi there",caret: 6, mode: .normal, pressedKey: "h",   caption: nil,                                                                 duration: 0.35),
        Beat(text: "hi there",caret: 5, mode: .normal, pressedKey: "h",   caption: nil,                                                                 duration: 0.35),
        Beat(text: "hi ther", caret: 5, mode: .normal, pressedKey: "x",   caption: "x deletes the character under the cursor.",                         duration: 0.8),
        Beat(text: "hi the",  caret: 5, mode: .normal, pressedKey: "x",   caption: nil,                                                                 duration: 0.4),
        Beat(text: "hi th",   caret: 5, mode: .normal, pressedKey: "x",   caption: nil,                                                                 duration: 0.4),
        Beat(text: "",        caret: 0, mode: .normal, pressedKey: "dd",  caption: "dd wipes the whole line.",                                          duration: 1.6),
        Beat(text: "",        caret: 0, mode: .insert, pressedKey: "i",   caption: "Press i. Back to typing.",                                          duration: 1.2),
        Beat(text: "d",       caret: 1, mode: .insert, pressedKey: "d",   caption: nil,                                                                 duration: 0.22),
        Beat(text: "do",      caret: 2, mode: .insert, pressedKey: "o",   caption: nil,                                                                 duration: 0.22),
        Beat(text: "don",     caret: 3, mode: .insert, pressedKey: "n",   caption: nil,                                                                 duration: 0.22),
        Beat(text: "done",    caret: 4, mode: .insert, pressedKey: "e",   caption: "Letters again. That's the whole dance.",                            duration: 2.4),
    ]
}

// MARK: - Parts

private struct CaretView: View {
    let mode: VimMode
    let visible: Bool

    var body: some View {
        // Insert caret is a thin line; Normal caret is a solid block —
        // mirrors the real terminal-Vim visual cue.
        Rectangle()
            .fill(mode.color)
            .frame(width: mode == .insert ? 2 : 13, height: 26)
            .opacity(visible ? 1 : 0.1)
            .animation(.easeInOut(duration: 0.12), value: mode)
    }
}

private struct ModeChip: View {
    let mode: VimMode

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(mode.color)
                .frame(width: 7, height: 7)
            Text(mode.displayName)
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background {
            Capsule().fill(mode.color.opacity(0.18))
        }
        .overlay {
            Capsule().strokeBorder(mode.color.opacity(0.45), lineWidth: 0.5)
        }
    }
}

private struct PressedKeyChip: View {
    let label: String

    var body: some View {
        // Slightly brighter than the passive KeyCapView so it reads as
        // "this key was just pressed" mid-sequence.
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
