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
                instruction: "Use f* to jump to the * and delete it with x",
                initialText: "Jump to the * in this line.",
                initialCursorPosition: 0,
                expectedText: "Jump to the  in this line.",
                expectedCursorPosition: nil,
                hints: ["Type f* to find the asterisk, then x to delete"],
                difficulty: .learn,
                drillCount: 10,
                variations: [
                    .init(initialText: "Find the * here.", initialCursorPosition: 0,
                          expectedText: "Find the  here.", expectedCursorPosition: nil),
                    .init(initialText: "Go to * quickly.", initialCursorPosition: 0,
                          expectedText: "Go to  quickly.", expectedCursorPosition: nil),
                    .init(initialText: "The * is here.", initialCursorPosition: 0,
                          expectedText: "The  is here.", expectedCursorPosition: nil),
                    .init(initialText: "Search for *.", initialCursorPosition: 0,
                          expectedText: "Search for .", expectedCursorPosition: nil),
                    .init(initialText: "Navigate to * now.", initialCursorPosition: 0,
                          expectedText: "Navigate to  now.", expectedCursorPosition: nil),
                    .init(initialText: "Spot the * mark.", initialCursorPosition: 0,
                          expectedText: "Spot the  mark.", expectedCursorPosition: nil),
                    .init(initialText: "Where is *?", initialCursorPosition: 0,
                          expectedText: "Where is ?", expectedCursorPosition: nil),
                    .init(initialText: "Move to * please.", initialCursorPosition: 0,
                          expectedText: "Move to  please.", expectedCursorPosition: nil),
                    .init(initialText: "Find * in text.", initialCursorPosition: 0,
                          expectedText: "Find  in text.", expectedCursorPosition: nil),
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
            .text("t is like f but stops one character before the target. Especially useful with delete: dt) deletes everything up to the closing paren."),
            .spacer,
            .keyCommand(keys: ["t", "x"], description: "Move to just before 'x'"),
            .keyCommand(keys: ["T", "x"], description: "Move to just after 'x' (backward)"),
            .spacer,
            .tip("f = find (land on it). t = till (stop just before)."),
        ],
        exercises: [
            Exercise(
                id: "ch4.l2.e1",
                instruction: "Use dt) to delete the UPPERCASE text inside the parens",
                initialText: "(DELETE THIS)",
                initialCursorPosition: 1,
                expectedText: "()",
                expectedCursorPosition: nil,
                hints: ["Position after (, then type dt)"],
                difficulty: .learn,
                drillCount: 10,
                variations: [
                    .init(initialText: "(REMOVE)", initialCursorPosition: 1,
                          expectedText: "()", expectedCursorPosition: nil),
                    .init(initialText: "(ERASE ALL)", initialCursorPosition: 1,
                          expectedText: "()", expectedCursorPosition: nil),
                    .init(initialText: "(CLEAN UP)", initialCursorPosition: 1,
                          expectedText: "()", expectedCursorPosition: nil),
                    .init(initialText: "(DROP THIS)", initialCursorPosition: 1,
                          expectedText: "()", expectedCursorPosition: nil),
                    .init(initialText: "(KILL IT)", initialCursorPosition: 1,
                          expectedText: "()", expectedCursorPosition: nil),
                    .init(initialText: "(CUT ME)", initialCursorPosition: 1,
                          expectedText: "()", expectedCursorPosition: nil),
                    .init(initialText: "(WIPE OUT)", initialCursorPosition: 1,
                          expectedText: "()", expectedCursorPosition: nil),
                    .init(initialText: "(ZAP)", initialCursorPosition: 1,
                          expectedText: "()", expectedCursorPosition: nil),
                    .init(initialText: "(CLEAR)", initialCursorPosition: 1,
                          expectedText: "()", expectedCursorPosition: nil),
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
                instruction: "Use f. to find the first period, then ; to reach the last one",
                initialText: "One. Two. Three.",
                initialCursorPosition: 0,
                expectedText: "One. Two. Three.",
                expectedCursorPosition: 15,
                hints: ["Type f. then ; twice to reach the third period"],
                difficulty: .learn
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
                instruction: "Use n to jump between occurrences of 'the'",
                initialText: "Find the word. The word is the one here.",
                initialCursorPosition: 0,
                expectedText: "Find the word. The word is the one here.",
                expectedCursorPosition: 27,
                hints: ["Search for 'the' with Cmd+F, close search, then use n to jump"],
                difficulty: .practice
            ),
        ],
        motionsIntroduced: ["n", "N"]
    )
}
