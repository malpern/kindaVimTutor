import SwiftUI

struct TypewriterText: View {
    let text: String
    let font: Font
    var foregroundStyle: AnyShapeStyle
    var alignment: TextAlignment
    var onComplete: (() -> Void)?

    @State private var displayedText = ""
    @State private var actions: [TypingAction] = []
    @State private var actionIndex = 0
    @State private var isComplete = false
    @State private var cursorVisible = true
    @State private var timer: Timer?
    @State private var cursorTimer: Timer?
    @State private var didFireCompletion = false

    private enum TypingAction {
        case type(Character)
        case backspace
        case pause(TimeInterval)
    }

    init(_ text: String,
         font: Font = .body,
         foregroundStyle: some ShapeStyle = .primary,
         alignment: TextAlignment = .leading,
         onComplete: (() -> Void)? = nil) {
        self.text = text
        self.font = font
        self.foregroundStyle = AnyShapeStyle(foregroundStyle)
        self.alignment = alignment
        self.onComplete = onComplete
    }

    private var frameAlignment: Alignment {
        switch alignment {
        case .center: .center
        case .trailing: .trailing
        default: .leading
        }
    }

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            Text(displayedText)
                .font(font)
                .foregroundStyle(foregroundStyle)
                .multilineTextAlignment(alignment)

            // Green blinking cursor
            if !isComplete {
                Text("▊")
                    .font(font)
                    .foregroundStyle(.green)
                    .opacity(cursorVisible ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: frameAlignment)
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

    private func startTyping() {
        displayedText = ""
        actions = buildTypingActions(for: text)
        actionIndex = 0
        isComplete = false
        didFireCompletion = false
        scheduleNextCharacter()
    }

    private func scheduleNextCharacter() {
        guard actionIndex < actions.count else {
            finishTyping()
            return
        }

        let nextAction = actions[actionIndex]
        let delay = typingDelay(for: nextAction)
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            Task { @MainActor in
                apply(nextAction)
                actionIndex += 1
                scheduleNextCharacter()
            }
        }
    }

    private func apply(_ action: TypingAction) {
        switch action {
        case .type(let char):
            displayedText.append(char)

        case .backspace:
            if !displayedText.isEmpty {
                displayedText.removeLast()
            }

        case .pause:
            break
        }
    }

    private func finishTyping() {
        displayedText = text
        isComplete = true
        guard !didFireCompletion else { return }
        didFireCompletion = true
        onComplete?()
    }

    private func typingDelay(for action: TypingAction) -> TimeInterval {
        switch action {
        case .pause(let duration):
            return duration

        case .backspace:
            return Double.random(in: 0.035...0.07)

        case .type(let char):
            var delay: TimeInterval = Double.random(in: 0.04...0.09)

            if ".!?".contains(char) {
                delay = Double.random(in: 0.22...0.38)
            } else if ",;:".contains(char) {
                delay = Double.random(in: 0.12...0.22)
            } else if char == " " {
                delay = Double.random(in: 0.06...0.12)
            } else if char == "\n" {
                delay = Double.random(in: 0.14...0.24)
            } else if char.isUppercase {
                delay += Double.random(in: 0.02...0.05)
            }

            return delay
        }
    }

    private func buildTypingActions(for text: String) -> [TypingAction] {
        let characters = Array(text)
        var builtActions: [TypingAction] = []

        for (index, char) in characters.enumerated() {
            builtActions.append(contentsOf: typoActionsIfNeeded(for: char, at: index, in: characters))
            builtActions.append(.type(char))
        }

        return builtActions
    }

    private func typoActionsIfNeeded(
        for char: Character,
        at index: Int,
        in characters: [Character]
    ) -> [TypingAction] {
        guard char.isLetter else { return [] }
        guard Double.random(in: 0...1) < 0.075 else { return [] }

        let previousCharacter = index > 0 ? characters[index - 1] : nil
        let nextCharacter = index + 1 < characters.count ? characters[index + 1] : nil
        let typoStyle = Int.random(in: 0...2)

        switch typoStyle {
        case 0:
            return [
                .type(neighboringTypo(for: char)),
                .pause(Double.random(in: 0.08...0.18)),
                .backspace,
                .pause(Double.random(in: 0.04...0.09)),
            ]

        case 1:
            return [
                .type(char),
                .pause(Double.random(in: 0.03...0.08)),
                .type(char),
                .pause(Double.random(in: 0.08...0.18)),
                .backspace,
                .pause(Double.random(in: 0.04...0.09)),
            ]

        default:
            let wrongSequence = shortMistypedFragment(
                intended: char,
                previous: previousCharacter,
                next: nextCharacter
            )

            var typoActions = wrongSequence.map(TypingAction.type)
            typoActions.append(.pause(Double.random(in: 0.1...0.2)))
            typoActions.append(contentsOf: Array(repeating: .backspace, count: wrongSequence.count))
            typoActions.append(.pause(Double.random(in: 0.05...0.1)))
            return typoActions
        }
    }

    private func neighboringTypo(for char: Character) -> Character {
        let lowercase = Character(String(char).lowercased())
        let neighborMap: [Character: [Character]] = [
            "a": ["s", "q", "z"],
            "b": ["v", "n", "g"],
            "c": ["x", "v", "d"],
            "d": ["s", "f", "e"],
            "e": ["w", "r", "d"],
            "f": ["d", "g", "r"],
            "g": ["f", "h", "t"],
            "h": ["g", "j", "y"],
            "i": ["u", "o", "k"],
            "j": ["h", "k", "u"],
            "k": ["j", "l", "i"],
            "l": ["k", "o", "p"],
            "m": ["n", "j", "k"],
            "n": ["b", "m", "h"],
            "o": ["i", "p", "l"],
            "p": ["o", "l"],
            "q": ["w", "a"],
            "r": ["e", "t", "f"],
            "s": ["a", "d", "w"],
            "t": ["r", "y", "g"],
            "u": ["y", "i", "j"],
            "v": ["c", "b", "f"],
            "w": ["q", "e", "s"],
            "x": ["z", "c", "s"],
            "y": ["t", "u", "h"],
            "z": ["x", "a"]
        ]

        let replacement = neighborMap[lowercase]?.randomElement() ?? lowercase
        let string = char.isUppercase ? String(replacement).uppercased() : String(replacement)
        return Character(string)
    }

    private func shortMistypedFragment(
        intended char: Character,
        previous: Character?,
        next: Character?
    ) -> [Character] {
        let first = neighboringTypo(for: char)

        if let next, next.isLetter, Double.random(in: 0...1) < 0.45 {
            return [first, neighboringTypo(for: next)]
        }

        if let previous, previous.isLetter, Double.random(in: 0...1) < 0.35 {
            return [previous, first]
        }

        return [first]
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
        finishTyping()
    }
}
