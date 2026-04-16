import Foundation

extension Curriculum {
    static let chapter5 = Chapter(
        id: "ch5",
        number: 5,
        title: "Visual Mode",
        subtitle: "Select, then act",
        systemImage: "selection.pin.in.out",
        lessons: [
            lesson5_1, lesson5_2, lesson5_3,
        ]
    )

    // MARK: - Lesson 5.1: Visual Character Mode

    private static let lesson5_1 = Lesson(
        id: "ch5.l1",
        number: 1,
        title: "Visual Character Mode",
        subtitle: "Select text with v",
        explanation: [
            .heading("See What You're About to Change"),
            .text("Press v to start selecting. Move to extend the selection. Then press an operator key to act on it."),
            .spacer,
            .keyCommand(keys: ["v"], description: "Start visual selection"),
            .spacer,
            .text("Visual mode flips the workflow: select first, then operate. Useful when you're not sure exactly how far to go."),
            .tip("Press Esc to cancel without doing anything."),
        ],
        exercises: [
            Exercise(
                id: "ch5.l1.e1",
                instruction: "Select the UPPERCASE text with v + motion, then delete with d",
                initialText: "Keep REMOVE THIS end.",
                initialCursorPosition: 5,
                expectedText: "Keep  end.",
                expectedCursorPosition: nil,
                hints: ["Press v, then w or e to select the words, then d to delete"],
                difficulty: .learn
            ),
        ],
        motionsIntroduced: ["v"]
    )

    // MARK: - Lesson 5.2: Visual Line Mode

    private static let lesson5_2 = Lesson(
        id: "ch5.l2",
        number: 2,
        title: "Visual Line Mode",
        subtitle: "Select whole lines with V",
        explanation: [
            .heading("Select Entire Lines"),
            .text("V (uppercase) selects whole lines. Move up/down to extend, then operate."),
            .spacer,
            .keyCommand(keys: ["V"], description: "Start visual line selection"),
            .spacer,
            .text("Perfect for deleting or moving blocks of lines."),
        ],
        exercises: [
            Exercise(
                id: "ch5.l2.e1",
                instruction: "Select the two marked lines with V + j, then delete with d",
                initialText: "Keep\n--- DELETE ---\n--- DELETE ---\nKeep",
                initialCursorPosition: 5,
                expectedText: "Keep\nKeep",
                expectedCursorPosition: nil,
                hints: ["On first DELETE line, press V, then j, then d"],
                difficulty: .learn
            ),
        ],
        motionsIntroduced: ["V"]
    )

    // MARK: - Lesson 5.3: Visual + Operators

    private static let lesson5_3 = Lesson(
        id: "ch5.l3",
        number: 3,
        title: "Visual + Operators",
        subtitle: "Select then delete, yank, or change",
        explanation: [
            .heading("Any Operator Works on a Selection"),
            .text("In Visual mode, any operator acts on the highlighted text:"),
            .spacer,
            .keyCommand(keys: ["d"], description: "Delete selection"),
            .keyCommand(keys: ["y"], description: "Yank (copy) selection"),
            .keyCommand(keys: ["c"], description: "Change (replace) selection"),
            .keyCommand(keys: ["~"], description: "Toggle case"),
            .keyCommand(keys: [">"], description: "Indent"),
        ],
        exercises: [
            Exercise(
                id: "ch5.l3.e1",
                instruction: "Select 'lower' with ve, then toggle its case to 'LOWER' with ~",
                initialText: "Make lower UPPER.",
                initialCursorPosition: 5,
                expectedText: "Make LOWER UPPER.",
                expectedCursorPosition: nil,
                hints: ["Press v, then e to select 'lower', then ~ to toggle case"],
                difficulty: .practice
            ),
        ],
        motionsIntroduced: ["v+d", "v+y", "v+c"]
    )
}
