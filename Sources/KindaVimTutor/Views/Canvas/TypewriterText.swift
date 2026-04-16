import SwiftUI

struct TypewriterText: View {
    let text: String
    let font: Font
    var foregroundStyle: AnyShapeStyle
    var onComplete: (() -> Void)?

    @State private var revealedCount: Int = 0
    @State private var isComplete = false
    @State private var cursorVisible = true
    @State private var timer: Timer?
    @State private var cursorTimer: Timer?

    init(_ text: String,
         font: Font = .body,
         foregroundStyle: some ShapeStyle = .primary,
         onComplete: (() -> Void)? = nil) {
        self.text = text
        self.font = font
        self.foregroundStyle = AnyShapeStyle(foregroundStyle)
        self.onComplete = onComplete
    }

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            Text(revealedText)
                .font(font)
                .foregroundStyle(foregroundStyle)

            // Green blinking cursor
            if !isComplete {
                Text("▊")
                    .font(font)
                    .foregroundStyle(.green)
                    .opacity(cursorVisible ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            skipToEnd()
        }
        .onAppear {
            startTyping()
            startCursorBlink()
        }
        .onDisappear {
            timer?.invalidate()
            cursorTimer?.invalidate()
        }
    }

    private var revealedText: String {
        if isComplete { return text }
        let index = text.index(text.startIndex, offsetBy: min(revealedCount, text.count))
        return String(text[..<index])
    }

    private func startTyping() {
        revealedCount = 0
        isComplete = false
        scheduleNextCharacter()
    }

    private func scheduleNextCharacter() {
        guard revealedCount < text.count else {
            isComplete = true
            onComplete?()
            return
        }

        let delay = typingDelay(for: revealedCount)
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            Task { @MainActor in
                revealedCount += 1
                scheduleNextCharacter()
            }
        }
    }

    private func typingDelay(for index: Int) -> TimeInterval {
        guard index < text.count else { return 0.03 }

        let char = text[text.index(text.startIndex, offsetBy: index)]

        // Base speed: fast enough to not annoy
        var delay: TimeInterval = Double.random(in: 0.02...0.045)

        // Punctuation pauses
        if ".!?".contains(char) {
            delay = Double.random(in: 0.12...0.2)
        } else if ",;:".contains(char) {
            delay = Double.random(in: 0.06...0.12)
        } else if char == " " {
            delay = Double.random(in: 0.03...0.06)
        } else if char == "\n" {
            delay = Double.random(in: 0.08...0.15)
        }

        // Occasional stutter (3% chance) — brief pause mid-word
        if Double.random(in: 0...1) < 0.03 {
            delay += Double.random(in: 0.1...0.25)
        }

        return delay
    }

    private func startCursorBlink() {
        cursorTimer = Timer.scheduledTimer(withTimeInterval: 0.53, repeats: true) { _ in
            Task { @MainActor in
                cursorVisible.toggle()
            }
        }
    }

    private func skipToEnd() {
        timer?.invalidate()
        revealedCount = text.count
        isComplete = true
        onComplete?()
    }
}
