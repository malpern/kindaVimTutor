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
                initialText: "\n\n\n// Go to UPPERCASE, v then e w e, then d\nKeep REMOVE THIS end.\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 67,
                expectedText: "\n\n\n// Go to UPPERCASE, v then e w e, then d\nKeep  end.\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Press v, then e w e to cover the UPPERCASE pair, then d"],
                difficulty: .learn,
                drillCount: 10,
                variations: [
                    .init(initialText: "\n\n\n\n\n\n// Go to UPPERCASE, v then e w e, then d\nGood DROP BAD ok.\n\n\n\n\n\n\n", initialCursorPosition: 69, expectedText: "\n\n\n\n\n\n// Go to UPPERCASE, v then e w e, then d\nGood  ok.\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n// Go to UPPERCASE, v then e w e, then d\nHi DELETE NOW bye.\n\n\n\n", initialCursorPosition: 2, expectedText: "\n\n\n\n\n\n\n\n\n// Go to UPPERCASE, v then e w e, then d\nHi  bye.\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Go to UPPERCASE, v then e w e, then d\nYes ERASE ALL no.\n\n", initialCursorPosition: 7, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Go to UPPERCASE, v then e w e, then d\nYes  no.\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n// Go to UPPERCASE, v then e w e, then d\nStay KILL IT gone.\n\n\n\n\n\n\n\n", initialCursorPosition: 66, expectedText: "\n\n\n\n\n// Go to UPPERCASE, v then e w e, then d\nStay  gone.\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n\n// Go to UPPERCASE, v then e w e, then d\nSee CUT ME done.\n", initialCursorPosition: 1, expectedText: "\n\n\n\n\n\n\n\n\n\n\n\n// Go to UPPERCASE, v then e w e, then d\nSee  done.\n", expectedCursorPosition: nil),
                ]
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
                initialText: "\n\n\n// Go to the first marked line, V then j, then d\nKeep\n--- DELETE ---\n--- DELETE ---\nKeep\n\n\n\n\n\n\n",
                initialCursorPosition: 0,
                expectedText: "\n\n\n// Go to the first marked line, V then j, then d\nKeep\nKeep\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["On first marked line, press V, then j, then d"],
                difficulty: .learn,
                drillCount: 10,
                variations: [
                    .init(initialText: "\n\n\n\n\n\n// Go to the first marked line, V then j, then d\nStart\ndrop me\ndrop me too\nEnd\n\n\n\n", initialCursorPosition: 85, expectedText: "\n\n\n\n\n\n// Go to the first marked line, V then j, then d\nStart\nEnd\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n// Go to the first marked line, V then j, then d\nhead\ncut line A\ncut line B\nfoot\n", initialCursorPosition: 4, expectedText: "\n\n\n\n\n\n\n\n\n// Go to the first marked line, V then j, then d\nhead\nfoot\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n// Go to the first marked line, V then j, then d\ntop\nremove A\nremove B\nbase\n\n\n\n\n\n\n", initialCursorPosition: 84, expectedText: "\n\n\n// Go to the first marked line, V then j, then d\ntop\nbase\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n// Go to the first marked line, V then j, then d\nline1\nkill1\nkill2\nline4\n\n\n\n\n", initialCursorPosition: 0, expectedText: "\n\n\n\n\n// Go to the first marked line, V then j, then d\nline1\nline4\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n// Go to the first marked line, V then j, then d\nalpha\ntrash1\ntrash2\nomega\n\n", initialCursorPosition: 2, expectedText: "\n\n\n\n\n\n\n\n// Go to the first marked line, V then j, then d\nalpha\nomega\n\n", expectedCursorPosition: nil),
                ]
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
                initialText: "\n\n\n// Go to \"lower\", ve then ~ to uppercase it\nMake lower UPPER.\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 68,
                expectedText: "\n\n\n// Go to \"lower\", ve then ~ to uppercase it\nMake LOWER UPPER.\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Press v, then e to select the lowercase word, then ~ to toggle case"],
                difficulty: .practice,
                drillCount: 10,
                variations: [
                    .init(initialText: "\n\n\n\n\n\n// Go to \"small\", ve then ~ to uppercase it\nFlip small BIG now.\n\n\n\n\n\n\n", initialCursorPosition: 71, expectedText: "\n\n\n\n\n\n// Go to \"small\", ve then ~ to uppercase it\nFlip SMALL BIG now.\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n// Go to \"one\", ve then ~ to uppercase it\nChange one TWO.\n\n\n\n", initialCursorPosition: 6, expectedText: "\n\n\n\n\n\n\n\n\n// Go to \"one\", ve then ~ to uppercase it\nChange ONE TWO.\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Go to \"fast\", ve then ~ to uppercase it\nToggle fast SLOW word.\n\n", initialCursorPosition: 8, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Go to \"fast\", ve then ~ to uppercase it\nToggle FAST SLOW word.\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n// Go to \"soft\", ve then ~ to uppercase it\nSwap soft HARD text.\n\n\n\n\n\n\n\n", initialCursorPosition: 72, expectedText: "\n\n\n\n\n// Go to \"soft\", ve then ~ to uppercase it\nSwap SOFT HARD text.\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n\n// Go to \"cool\", ve then ~ to uppercase it\nSwitch cool HOT heat.\n", initialCursorPosition: 11, expectedText: "\n\n\n\n\n\n\n\n\n\n\n\n// Go to \"cool\", ve then ~ to uppercase it\nSwitch COOL HOT heat.\n", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["v+d", "v+y", "v+c"]
    )
}
