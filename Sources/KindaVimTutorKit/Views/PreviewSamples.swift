import SwiftUI

/// Sample data used only by `#Preview` blocks. Kept in one place so each view
/// file can render without duplicating realistic fixtures.
///
/// This file participates in release builds (SPM has no dedicated preview
/// target), but the overhead is small — just literal values.
enum PreviewSamples {
    static let exercise = Exercise(
        id: "preview.ex1",
        instruction: "Move the cursor to the end of the word with e",
        initialText: "hello world",
        initialCursorPosition: 0,
        expectedText: "hello world",
        expectedCursorPosition: 4,
        hints: ["e moves to the end of the current word"],
        difficulty: .learn,
        drillCount: 3
    )

    static let blocks: [ContentBlock] = [
        .heading("Your Hands Stay on Home Row"),
        .text("In Vim, you navigate without arrow keys. Instead you use four keys right under your right hand."),
        .keyCommand(keys: ["h"], description: "move left"),
        .keyCommand(keys: ["j"], description: "move down"),
        .keyCommand(keys: ["k"], description: "move up"),
        .keyCommand(keys: ["l"], description: "move right"),
        .tip("Think of it as a rhythm: h-j-k-l under your fingers, always."),
        .codeExample(before: "the quick brown fox", after: "the quick brown fox", motion: "l"),
    ]

    static let lesson = Lesson(
        id: "preview.l1",
        number: 1,
        title: "Moving the Cursor",
        subtitle: "Navigate with h, j, k, l",
        explanation: blocks,
        exercises: [exercise],
        motionsIntroduced: ["h", "j", "k", "l"]
    )

    static let chapter = Chapter(
        id: "preview.ch1",
        number: 1,
        title: "Survival Kit",
        subtitle: "The essentials",
        systemImage: "figure.walk",
        lessons: [lesson]
    )
}
