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
        subtitle: "Select text character by character with v",
        explanation: [
            .heading("See What You're About to Change"),
            .text("Press v to enter Visual mode. As you move the cursor, text is highlighted. Then apply any operator (d, y, c) to act on the selection."),
            .spacer,
            .keyCommand(keys: ["v"], description: "Enter Visual character mode"),
            .spacer,
            .text("Visual mode flips the workflow: instead of operator-then-motion, you select first, then operate. This is useful when you're not sure exactly how much text to affect."),
            .tip("Press Esc to cancel Visual mode without doing anything."),
        ],
        exercises: [
            Exercise(
                id: "ch5.l1.e1",
                instruction: "Select \"REMOVE THIS\" with v and motions, then delete with d",
                initialText: "Keep REMOVE THIS end.",
                initialCursorPosition: 5,
                expectedText: "Keep end.",
                expectedCursorPosition: nil,
                hints: ["Press v, then use l or w to select 'REMOVE THIS ', then press d"],
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
            .heading("Select Entire Lines at Once"),
            .text("Press V (uppercase) to select entire lines. Move up or down to extend the selection, then operate."),
            .spacer,
            .keyCommand(keys: ["V"], description: "Enter Visual line mode"),
            .spacer,
            .text("This is perfect for deleting, moving, or copying multiple lines. Select them with V and j/k, then d to delete or y to copy."),
        ],
        exercises: [
            Exercise(
                id: "ch5.l2.e1",
                instruction: "Select the two middle lines with V and j, then delete with d",
                initialText: "Keep this\nRemove this\nRemove this too\nKeep this also",
                initialCursorPosition: 10,
                expectedText: "Keep this\nKeep this also",
                expectedCursorPosition: nil,
                hints: ["On 'Remove this', press V, then j to extend to next line, then d"],
                difficulty: .learn
            ),
        ],
        motionsIntroduced: ["V"]
    )

    // MARK: - Lesson 5.3: Visual Mode with Operators

    private static let lesson5_3 = Lesson(
        id: "ch5.l3",
        number: 3,
        title: "Visual + Operators",
        subtitle: "Select then delete, yank, or change",
        explanation: [
            .heading("Any Operator Works on a Selection"),
            .text("In Visual mode, any operator key acts on the selected text:"),
            .spacer,
            .keyCommand(keys: ["d"], description: "Delete selection"),
            .keyCommand(keys: ["y"], description: "Yank (copy) selection"),
            .keyCommand(keys: ["c"], description: "Change selection (delete + insert)"),
            .keyCommand(keys: [">"], description: "Indent selection"),
            .keyCommand(keys: ["<"], description: "Outdent selection"),
            .keyCommand(keys: ["~"], description: "Toggle case of selection"),
            .spacer,
            .tip("Visual mode is great when you want to be precise about what you're affecting."),
        ],
        exercises: [
            Exercise(
                id: "ch5.l3.e1",
                instruction: "Select 'hello' with v and motions, then toggle its case to 'HELLO' with ~",
                initialText: "Say hello to the world.",
                initialCursorPosition: 4,
                expectedText: "Say HELLO to the world.",
                expectedCursorPosition: nil,
                hints: ["Press v, then e to select 'hello', then ~ to toggle case"],
                difficulty: .practice
            ),
        ],
        motionsIntroduced: ["v+d", "v+y", "v+c"]
    )
}
