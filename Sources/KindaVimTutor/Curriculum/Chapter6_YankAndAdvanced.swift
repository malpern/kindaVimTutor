import Foundation

extension Curriculum {
    static let chapter6 = Chapter(
        id: "ch6",
        number: 6,
        title: "Yank & Advanced",
        subtitle: "Copy, indent, navigate, and more",
        systemImage: "star",
        lessons: [
            lesson6_1, lesson6_2, lesson6_3, lesson6_4, lesson6_5, lesson6_6, lesson6_7,
        ]
    )

    // MARK: - Lesson 6.1: Yank (Copy)

    private static let lesson6_1 = Lesson(
        id: "ch6.l1",
        number: 1,
        title: "Yank (Copy)",
        subtitle: "Copy text with y",
        explanation: [
            .heading("Copy Without Deleting"),
            .text("The yank operator y copies text without removing it. Like d, it combines with motions:"),
            .spacer,
            .keyCommand(keys: ["y", "w"], description: "Yank (copy) a word"),
            .keyCommand(keys: ["y", "$"], description: "Yank to end of line"),
            .keyCommand(keys: ["y", "f", "x"], description: "Yank to character 'x'"),
            .spacer,
            .text("After yanking, press p to paste the copied text. This is Vim's copy-paste: y to copy, p to paste."),
            .tip("In Vim, 'yank' means copy. It's called yank because c was already taken by 'change'."),
        ],
        exercises: [
            Exercise(
                id: "ch6.l1.e1",
                instruction: "Yank the first word with yw, move to the end, and paste with p",
                initialText: "Hello world",
                initialCursorPosition: 0,
                expectedText: "Hello worldHello ",
                expectedCursorPosition: nil,
                hints: ["Press yw to copy 'Hello ', move to end with $, press p to paste"],
                difficulty: .learn
            ),
        ],
        motionsIntroduced: ["yw", "y$"]
    )

    // MARK: - Lesson 6.2: Yank Line

    private static let lesson6_2 = Lesson(
        id: "ch6.l2",
        number: 2,
        title: "Yank Line",
        subtitle: "Copy entire lines with yy",
        explanation: [
            .heading("Copy a Whole Line"),
            .text("Press yy to yank (copy) the entire current line. Then move to where you want it and press p to paste below or P to paste above."),
            .spacer,
            .keyCommand(keys: ["y", "y"], description: "Yank entire line"),
            .keyCommand(keys: ["Y"], description: "Also yanks entire line"),
            .spacer,
            .text("This is the copy equivalent of dd. Together, yy and p let you duplicate lines quickly."),
        ],
        exercises: [
            Exercise(
                id: "ch6.l2.e1",
                instruction: "Duplicate the first line by yanking it with yy and pasting with p",
                initialText: "Duplicate me\nSecond line",
                initialCursorPosition: 0,
                expectedText: "Duplicate me\nDuplicate me\nSecond line",
                expectedCursorPosition: nil,
                hints: ["Press yy to copy the line, then p to paste it below"],
                difficulty: .learn
            ),
        ],
        motionsIntroduced: ["yy", "Y"]
    )

    // MARK: - Lesson 6.3: Toggle Case

    private static let lesson6_3 = Lesson(
        id: "ch6.l3",
        number: 3,
        title: "Toggle Case",
        subtitle: "Swap case with ~",
        explanation: [
            .heading("Switch Between Upper and Lowercase"),
            .text("Press ~ to toggle the case of the character under the cursor and move to the next character."),
            .spacer,
            .keyCommand(keys: ["~"], description: "Toggle case and advance cursor"),
            .spacer,
            .text("Hold ~ to rapidly toggle a whole word's case. Or use it in Visual mode to toggle the entire selection."),
        ],
        exercises: [
            Exercise(
                id: "ch6.l3.e1",
                instruction: "Toggle 'hello' to 'HELLO' by pressing ~ five times",
                initialText: "Say hello world.",
                initialCursorPosition: 4,
                expectedText: "Say HELLO world.",
                expectedCursorPosition: nil,
                hints: ["Position on 'h', then press ~ five times"],
                difficulty: .learn,
                drillCount: 5,
                variations: [
                    .init(initialText: "The word world here.", initialCursorPosition: 9,
                          expectedText: "The word WORLD here.", expectedCursorPosition: nil),
                    .init(initialText: "Make THIS lowercase.", initialCursorPosition: 5,
                          expectedText: "Make this lowercase.", expectedCursorPosition: nil),
                    .init(initialText: "Toggle vim case.", initialCursorPosition: 7,
                          expectedText: "Toggle VIM case.", expectedCursorPosition: nil),
                    .init(initialText: "Change test here.", initialCursorPosition: 7,
                          expectedText: "Change TEST here.", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["~"]
    )

    // MARK: - Lesson 6.4: Indent and Outdent

    private static let lesson6_4 = Lesson(
        id: "ch6.l4",
        number: 4,
        title: "Indent and Outdent",
        subtitle: "Shift lines with >> and <<",
        explanation: [
            .heading("Shift Lines Left and Right"),
            .text("Press >> to indent the current line, or << to outdent it. These work with counts too."),
            .spacer,
            .keyCommand(keys: [">", ">"], description: "Indent current line"),
            .keyCommand(keys: ["<", "<"], description: "Outdent current line"),
            .spacer,
            .text("In Visual mode, > and < indent or outdent all selected lines at once."),
            .tip("These are especially useful for fixing code indentation."),
        ],
        exercises: [
            Exercise(
                id: "ch6.l4.e1",
                instruction: "Indent the line using >>",
                initialText: "Indent this line.",
                initialCursorPosition: 0,
                expectedText: "    Indent this line.",
                expectedCursorPosition: nil,
                hints: ["Press >> to indent the line"],
                difficulty: .learn
            ),
        ],
        motionsIntroduced: [">>", "<<"]
    )

    // MARK: - Lesson 6.5: Document Navigation

    private static let lesson6_5 = Lesson(
        id: "ch6.l5",
        number: 5,
        title: "Document Navigation",
        subtitle: "Jump anywhere with gg and G",
        explanation: [
            .heading("Jump to the Top or Bottom"),
            .text("gg jumps to the first line of the file. G jumps to the last line. A number before G jumps to that line number."),
            .spacer,
            .keyCommand(keys: ["g", "g"], description: "Jump to first line"),
            .keyCommand(keys: ["G"], description: "Jump to last line"),
            .keyCommand(keys: ["5", "G"], description: "Jump to line 5"),
            .spacer,
            .tip("These work great with operators too: dG deletes from here to the end of the file, dgg deletes to the top."),
        ],
        exercises: [
            Exercise(
                id: "ch6.l5.e1",
                instruction: "Jump from the middle to the first line using gg",
                initialText: "First line\nSecond line\nThird line\nFourth line\nFifth line",
                initialCursorPosition: 23,
                expectedText: "First line\nSecond line\nThird line\nFourth line\nFifth line",
                expectedCursorPosition: 0,
                hints: ["Press gg to jump to the very first line"],
                difficulty: .learn,
                drillCount: 5,
                variations: [
                    .init(initialText: "Top\nMiddle\nBottom", initialCursorPosition: 11,
                          expectedText: "Top\nMiddle\nBottom", expectedCursorPosition: 0),
                    .init(initialText: "A\nB\nC\nD\nE", initialCursorPosition: 8,
                          expectedText: "A\nB\nC\nD\nE", expectedCursorPosition: 0),
                    .init(initialText: "One\nTwo\nThree\nFour", initialCursorPosition: 14,
                          expectedText: "One\nTwo\nThree\nFour", expectedCursorPosition: 0),
                    .init(initialText: "Start\nMiddle\nEnd", initialCursorPosition: 13,
                          expectedText: "Start\nMiddle\nEnd", expectedCursorPosition: 0),
                ]
            ),
        ],
        motionsIntroduced: ["gg", "G"]
    )

    // MARK: - Lesson 6.6: Substitute

    private static let lesson6_6 = Lesson(
        id: "ch6.l6",
        number: 6,
        title: "Substitute",
        subtitle: "Delete character and type with s and S",
        explanation: [
            .heading("Delete and Start Typing in One Key"),
            .text("s deletes the character under the cursor and enters Insert mode. S deletes the entire line and enters Insert mode."),
            .spacer,
            .keyCommand(keys: ["s"], description: "Substitute character (delete + insert)"),
            .keyCommand(keys: ["S"], description: "Substitute line (delete all + insert)"),
            .spacer,
            .text("s is like x followed by i — it deletes one character and immediately lets you type. S is like cc."),
        ],
        exercises: [
            Exercise(
                id: "ch6.l6.e1",
                instruction: "Use s to replace the wrong character with the right one",
                initialText: "The cot sat down.",
                initialCursorPosition: 4,
                expectedText: "The cat sat down.",
                expectedCursorPosition: nil,
                hints: ["Move to 'o' in 'cot', press s, type 'a', press Esc"],
                difficulty: .learn,
                drillCount: 5,
                variations: [
                    .init(initialText: "He wint home.", initialCursorPosition: 4,
                          expectedText: "He went home.", expectedCursorPosition: nil),
                    .init(initialText: "A big deg ran.", initialCursorPosition: 8,
                          expectedText: "A big dog ran.", expectedCursorPosition: nil),
                    .init(initialText: "The sin shone.", initialCursorPosition: 5,
                          expectedText: "The sun shone.", expectedCursorPosition: nil),
                    .init(initialText: "She rod a bike.", initialCursorPosition: 5,
                          expectedText: "She rode a bike.", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["s", "S"]
    )

    // MARK: - Lesson 6.7: Replace Mode

    private static let lesson6_7 = Lesson(
        id: "ch6.l7",
        number: 7,
        title: "Replace Mode",
        subtitle: "Overwrite text with R",
        explanation: [
            .heading("Type Over Existing Text"),
            .text("Press R to enter Replace mode. Every character you type overwrites the character under the cursor, then advances. Press Esc to return to Normal mode."),
            .spacer,
            .keyCommand(keys: ["R"], description: "Enter Replace mode (overwrite)"),
            .spacer,
            .text("Replace mode is like Insert mode, but instead of pushing text to the right, it replaces what's already there. Useful for fixing sequences of characters."),
        ],
        exercises: [
            Exercise(
                id: "ch6.l7.e1",
                instruction: "Use R to overwrite 'xxx' with '123'",
                initialText: "The code is xxx here.",
                initialCursorPosition: 12,
                expectedText: "The code is 123 here.",
                expectedCursorPosition: nil,
                hints: ["Move to the first 'x', press R, type '123', press Esc"],
                difficulty: .learn,
                drillCount: 5,
                variations: [
                    .init(initialText: "Replace xxx now.", initialCursorPosition: 8,
                          expectedText: "Replace 456 now.", expectedCursorPosition: nil),
                    .init(initialText: "Fix the xxx value.", initialCursorPosition: 8,
                          expectedText: "Fix the 789 value.", expectedCursorPosition: nil),
                    .init(initialText: "Set to xxx please.", initialCursorPosition: 7,
                          expectedText: "Set to abc please.", expectedCursorPosition: nil),
                    .init(initialText: "Change xxx here.", initialCursorPosition: 7,
                          expectedText: "Change end here.", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["R"]
    )
}
