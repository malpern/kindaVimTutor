import Foundation

extension Curriculum {
    static let chapter4 = Chapter(
        id: "ch4",
        number: 4,
        title: "Search & Find",
        subtitle: "Jump to any character on the line",
        systemImage: "magnifyingglass",
        lessons: [
            lesson4_1, lesson4_2, lesson4_3, lesson4_4,
        ]
    )

    // MARK: - Lesson 4.1: Find Character

    private static let lesson4_1 = Lesson(
        id: "ch4.l1",
        number: 1,
        title: "Find Character",
        subtitle: "Jump to a character with f and F",
        explanation: [
            .heading("Jump to Any Character on the Line"),
            .text("Press f followed by a character to jump forward to it. F jumps backward. Much faster than pressing l repeatedly."),
            .spacer,
            .keyCommand(keys: ["f", "x"], description: "Find 'x' forward on this line"),
            .keyCommand(keys: ["F", "x"], description: "Find 'x' backward on this line"),
            .spacer,
            .tip("f lands ON the character. Great for navigating to a specific spot, then acting on it."),
        ],
        exercises: [
            Exercise(
                id: "ch4.l1.e1",
                instruction: "Use `f`* to jump to the * and delete it with `x`",
                initialText: "\n\n\n// Use f* to jump to *, then x to delete it\nThe * is lost here\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 0,
                expectedText: "\n\n\n// Use f* to jump to *, then x to delete it\nThe  is lost here\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Type `f`* to find the asterisk, then `x` to delete"],
                difficulty: .learn,
                drillCount: 6,
                variations: [
                    .init(initialText: "\n\n\n\n\n\n// Use f* to jump to *, then x to delete it\nPlease find * now\n\n\n\n\n\n\n", initialCursorPosition: 5, expectedText: "\n\n\n\n\n\n// Use f* to jump to *, then x to delete it\nPlease find  now\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n// Use f* to jump to *, then x to delete it\nA * needs removing\n\n\n\n", initialCursorPosition: 74, expectedText: "\n\n\n\n\n\n\n\n\n// Use f* to jump to *, then x to delete it\nA  needs removing\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Use f* to jump to *, then x to delete it\nSpot the * in text\n\n", initialCursorPosition: 6, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Use f* to jump to *, then x to delete it\nSpot the  in text\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n// Use f* to jump to *, then x to delete it\nWhere is the * mark\n\n\n\n\n\n\n\n", initialCursorPosition: 4, expectedText: "\n\n\n\n\n// Use f* to jump to *, then x to delete it\nWhere is the  mark\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n\n// Use f* to jump to *, then x to delete it\nLocate the * fast\n", initialCursorPosition: 74, expectedText: "\n\n\n\n\n\n\n\n\n\n\n\n// Use f* to jump to *, then x to delete it\nLocate the  fast\n", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["f", "F"]
    )

    // MARK: - Lesson 4.2: Till Character

    private static let lesson4_2 = Lesson(
        id: "ch4.l2",
        number: 2,
        title: "Till Character",
        subtitle: "Stop just before with t and T",
        explanation: [
            .heading("Jump to Just Before a Character"),
            .text("`t` is like `f` but stops one character before the target. Especially useful with delete: `dt)` deletes everything up to the closing paren."),
            .spacer,
            .findVsTill,
            .spacer,
            .keyCommand(keys: ["t", "x"], description: "Move to just before 'x'"),
            .keyCommand(keys: ["T", "x"], description: "Move to just after 'x' (backward)"),
            .spacer,
            .tip("`f` = find (land on it). `t` = till (stop just before)."),
        ],
        exercises: [
            Exercise(
                id: "ch4.l2.e1",
                instruction: "Use dt) to delete the UPPERCASE text inside the parens",
                initialText: "\n\n\n// Navigate onto (, then dt) to delete up to )\n(REMOVE THIS)\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 65,
                expectedText: "\n\n\n// Navigate onto (, then dt) to delete up to )\n()\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Position after (, then type dt)"],
                difficulty: .learn,
                drillCount: 6,
                variations: [
                    .init(initialText: "\n\n\n\n\n\n// Navigate onto (, then dt) to delete up to )\n(ERASE ALL)\n\n\n\n\n\n\n", initialCursorPosition: 3, expectedText: "\n\n\n\n\n\n// Navigate onto (, then dt) to delete up to )\n()\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n// Navigate onto (, then dt) to delete up to )\n(CLEAN UP NOW)\n\n\n\n", initialCursorPosition: 4, expectedText: "\n\n\n\n\n\n\n\n\n// Navigate onto (, then dt) to delete up to )\n()\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Navigate onto (, then dt) to delete up to )\n(DROP THE TEXT)\n\n", initialCursorPosition: 3, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Navigate onto (, then dt) to delete up to )\n()\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n// Navigate onto (, then dt) to delete up to )\n(KILL IT NOW)\n\n\n\n\n\n\n\n", initialCursorPosition: 67, expectedText: "\n\n\n\n\n// Navigate onto (, then dt) to delete up to )\n()\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n\n// Navigate onto (, then dt) to delete up to )\n(WIPE IT OUT)\n", initialCursorPosition: 10, expectedText: "\n\n\n\n\n\n\n\n\n\n\n\n// Navigate onto (, then dt) to delete up to )\n()\n", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["t", "T"]
    )

    // MARK: - Lesson 4.3: Repeat Find

    private static let lesson4_3 = Lesson(
        id: "ch4.l3",
        number: 3,
        title: "Repeat Find",
        subtitle: "Jump again with ; and ,",
        explanation: [
            .heading("Repeat Your Last f or t"),
            .text("After using f or t, press ; to repeat the search forward, or , to go backward."),
            .spacer,
            .keyCommand(keys: [";"], description: "Repeat last f/t (same direction)"),
            .keyCommand(keys: [","], description: "Repeat last f/t (opposite direction)"),
            .spacer,
            .text("Hop between occurrences without retyping the search."),
        ],
        exercises: [
            Exercise(
                id: "ch4.l3.e1",
                instruction: "Use `f`. to find the first period, then `;` to reach the last one",
                initialText: "\n\n\n// Use f. then ; repeatedly to reach the LAST period\nOne. Two. Three.\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 75,
                expectedText: "\n\n\n// Use f. then ; repeatedly to reach the LAST period\nOne. Two. Three.\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: 71,
                hints: ["Type `f`. then `;` twice to reach the last period"],
                difficulty: .learn,
                drillCount: 6,
                variations: [
                    .init(initialText: "\n\n\n\n\n\n// Use f. then ; repeatedly to reach the LAST period\nRed. Blue. Green.\n\n\n\n\n\n\n", initialCursorPosition: 77, expectedText: "\n\n\n\n\n\n// Use f. then ; repeatedly to reach the LAST period\nRed. Blue. Green.\n\n\n\n\n\n\n", expectedCursorPosition: 75),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n// Use f. then ; repeatedly to reach the LAST period\nA. B. C.\n\n\n\n", initialCursorPosition: 7, expectedText: "\n\n\n\n\n\n\n\n\n// Use f. then ; repeatedly to reach the LAST period\nA. B. C.\n\n\n\n", expectedCursorPosition: 69),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Use f. then ; repeatedly to reach the LAST period\nStart. Middle. End.\n\n", initialCursorPosition: 5, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Use f. then ; repeatedly to reach the LAST period\nStart. Middle. End.\n\n", expectedCursorPosition: 82),
                    .init(initialText: "\n\n\n\n\n// Use f. then ; repeatedly to reach the LAST period\nLeft. Right. Last.\n\n\n\n\n\n\n\n", initialCursorPosition: 78, expectedText: "\n\n\n\n\n// Use f. then ; repeatedly to reach the LAST period\nLeft. Right. Last.\n\n\n\n\n\n\n\n", expectedCursorPosition: 75),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n\n// Use f. then ; repeatedly to reach the LAST period\nUp. Mid. Down.\n", initialCursorPosition: 2, expectedText: "\n\n\n\n\n\n\n\n\n\n\n\n// Use f. then ; repeatedly to reach the LAST period\nUp. Mid. Down.\n", expectedCursorPosition: 78),
                ]
            ),
        ],
        motionsIntroduced: [";", ","]
    )

    // MARK: - Lesson 4.4: Search Next/Previous

    private static let lesson4_4 = Lesson(
        id: "ch4.l4",
        number: 4,
        title: "Search Navigation",
        subtitle: "Jump between matches with n and N",
        explanation: [
            .heading("Navigate Search Matches"),
            .text("After searching with Cmd+F in your app, use n to jump to the next match and N for previous."),
            .spacer,
            .keyCommand(keys: ["n"], description: "Next search match"),
            .keyCommand(keys: ["N"], description: "Previous search match"),
        ],
        exercises: [
            Exercise(
                id: "ch4.l4.e1",
                instruction: "Use `n` to jump between occurrences of 'the'",
                initialText: "\n\n\n// Cmd+F search \"the\", close search, then n to reach the 3rd match\nFind the word. The word is the one here.\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 2,
                expectedText: "\n\n\n// Cmd+F search \"the\", close search, then n to reach the 3rd match\nFind the word. The word is the one here.\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: 97,
                hints: ["Search for 'the' with `Cmd+F`, close search, then use `n` to jump"],
                difficulty: .practice,
                drillCount: 6,
                variations: [
                    .init(initialText: "\n\n\n\n\n\n// Cmd+F search \"the\", close search, then n to reach the 3rd match\nSee the dog. The dog saw the cat.\n\n\n\n\n\n\n", initialCursorPosition: 112, expectedText: "\n\n\n\n\n\n// Cmd+F search \"the\", close search, then n to reach the 3rd match\nSee the dog. The dog saw the cat.\n\n\n\n\n\n\n", expectedCursorPosition: 98),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n// Cmd+F search \"the\", close search, then n to reach the 3rd match\nPut the box. The box holds the key.\n\n\n\n", initialCursorPosition: 112, expectedText: "\n\n\n\n\n\n\n\n\n// Cmd+F search \"the\", close search, then n to reach the 3rd match\nPut the box. The box holds the key.\n\n\n\n", expectedCursorPosition: 103),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Cmd+F search \"the\", close search, then n to reach the 3rd match\nGet the cup. The cup has the tea.\n\n", initialCursorPosition: 5, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Cmd+F search \"the\", close search, then n to reach the 3rd match\nGet the cup. The cup has the tea.\n\n", expectedCursorPosition: 103),
                    .init(initialText: "\n\n\n\n\n// Cmd+F search \"the\", close search, then n to reach the 3rd match\nUse the pen. The pen needs the ink.\n\n\n\n\n\n\n\n", initialCursorPosition: 115, expectedText: "\n\n\n\n\n// Cmd+F search \"the\", close search, then n to reach the 3rd match\nUse the pen. The pen needs the ink.\n\n\n\n\n\n\n\n", expectedCursorPosition: 99),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n\n// Cmd+F search \"the\", close search, then n to reach the 3rd match\nTake the map. The map shows the road.\n", initialCursorPosition: 6, expectedText: "\n\n\n\n\n\n\n\n\n\n\n\n// Cmd+F search \"the\", close search, then n to reach the 3rd match\nTake the map. The map shows the road.\n", expectedCursorPosition: 107),
                ]
            ),
        ],
        motionsIntroduced: ["n", "N"]
    )
}
