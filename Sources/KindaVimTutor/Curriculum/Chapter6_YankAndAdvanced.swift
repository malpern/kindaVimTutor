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
            .text("The yank operator y copies text without removing it. Combine with motions just like d:"),
            .spacer,
            .keyCommand(keys: ["y", "w"], description: "Yank a word"),
            .keyCommand(keys: ["y", "$"], description: "Yank to end of line"),
            .spacer,
            .text("After yanking, press p to paste. y to copy, p to paste."),
            .tip("'Yank' means copy. It's called yank because c was already taken by 'change'."),
        ],
        exercises: [
            Exercise(
                id: "ch6.l1.e1",
                instruction: "Copy 'Hello ' with yw, move to end with $, paste with p",
                initialText: "Hello world",
                initialCursorPosition: 0,
                expectedText: "Hello worldHello ",
                expectedCursorPosition: nil,
                hints: ["Press yw, then $, then p"],
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
            .text("yy yanks the entire line. Move to where you want it and press p to paste below."),
            .spacer,
            .keyCommand(keys: ["y", "y"], description: "Yank entire line"),
            .spacer,
            .text("Together, yy and p duplicate lines quickly."),
        ],
        exercises: [
            Exercise(
                id: "ch6.l2.e1",
                instruction: "Duplicate the line: yy to copy, then p to paste below",
                initialText: "Copy me\nSecond line",
                initialCursorPosition: 0,
                expectedText: "Copy me\nCopy me\nSecond line",
                expectedCursorPosition: nil,
                hints: ["Press yy, then p"],
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
            .heading("Switch Upper and Lowercase"),
            .text("~ toggles the case of the character under the cursor and advances."),
            .spacer,
            .keyCommand(keys: ["~"], description: "Toggle case and advance"),
        ],
        exercises: [
            Exercise(
                id: "ch6.l3.e1",
                instruction: "Toggle the lowercase word to UPPERCASE by pressing ~ repeatedly",
                initialText: "Make hello loud.",
                initialCursorPosition: 5,
                expectedText: "Make HELLO loud.",
                expectedCursorPosition: nil,
                hints: ["Position on 'h', press ~ five times"],
                difficulty: .learn,
                drillCount: 10,
                variations: [
                    .init(initialText: "Say world here.", initialCursorPosition: 4,
                          expectedText: "Say WORLD here.", expectedCursorPosition: nil),
                    .init(initialText: "The word code.", initialCursorPosition: 9,
                          expectedText: "The word CODE.", expectedCursorPosition: nil),
                    .init(initialText: "Fix THIS now.", initialCursorPosition: 4,
                          expectedText: "Fix this now.", expectedCursorPosition: nil),
                    .init(initialText: "Toggle vim key.", initialCursorPosition: 7,
                          expectedText: "Toggle VIM key.", expectedCursorPosition: nil),
                    .init(initialText: "Make test pass.", initialCursorPosition: 5,
                          expectedText: "Make TEST pass.", expectedCursorPosition: nil),
                    .init(initialText: "Set true flag.", initialCursorPosition: 4,
                          expectedText: "Set TRUE flag.", expectedCursorPosition: nil),
                    .init(initialText: "Use CAPS lock.", initialCursorPosition: 4,
                          expectedText: "Use caps lock.", expectedCursorPosition: nil),
                    .init(initialText: "Run fast now.", initialCursorPosition: 4,
                          expectedText: "Run FAST now.", expectedCursorPosition: nil),
                    .init(initialText: "Go HOME soon.", initialCursorPosition: 3,
                          expectedText: "Go home soon.", expectedCursorPosition: nil),
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
            .text(">> indents the current line. << outdents it."),
            .spacer,
            .keyCommand(keys: [">", ">"], description: "Indent line"),
            .keyCommand(keys: ["<", "<"], description: "Outdent line"),
        ],
        exercises: [
            Exercise(
                id: "ch6.l4.e1",
                instruction: "Indent this line using >>",
                initialText: "Indent me.",
                initialCursorPosition: 0,
                expectedText: "    Indent me.",
                expectedCursorPosition: nil,
                hints: ["Press >> to indent"],
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
        subtitle: "Jump with gg and G",
        explanation: [
            .heading("Jump to Top or Bottom"),
            .text("gg goes to the first line. G goes to the last. A number before G goes to that line."),
            .spacer,
            .keyCommand(keys: ["g", "g"], description: "First line"),
            .keyCommand(keys: ["G"], description: "Last line"),
        ],
        exercises: [
            Exercise(
                id: "ch6.l5.e1",
                instruction: "Jump to the first line using gg, then delete the * with x",
                initialText: "* delete me\nLine two\nLine three\nYou start here",
                initialCursorPosition: 36,
                expectedText: " delete me\nLine two\nLine three\nYou start here",
                expectedCursorPosition: nil,
                hints: ["Press gg to jump to top, then x to delete *"],
                difficulty: .learn,
                drillCount: 5,
                variations: [
                    .init(initialText: "* target\nA\nB\nC\nStart", initialCursorPosition: 17,
                          expectedText: " target\nA\nB\nC\nStart", expectedCursorPosition: nil),
                    .init(initialText: "* here\nSkip\nSkip\nBegin", initialCursorPosition: 18,
                          expectedText: " here\nSkip\nSkip\nBegin", expectedCursorPosition: nil),
                    .init(initialText: "* go\nA\nB\nC\nD\nE", initialCursorPosition: 14,
                          expectedText: " go\nA\nB\nC\nD\nE", expectedCursorPosition: nil),
                    .init(initialText: "* top\nMiddle\nBottom", initialCursorPosition: 12,
                          expectedText: " top\nMiddle\nBottom", expectedCursorPosition: nil),
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
        subtitle: "Quick replace with s",
        explanation: [
            .heading("Delete and Type in One Key"),
            .text("s deletes the character under cursor and enters Insert mode. Like x + i combined."),
            .spacer,
            .keyCommand(keys: ["s"], description: "Substitute character"),
            .keyCommand(keys: ["S"], description: "Substitute entire line"),
        ],
        exercises: [
            Exercise(
                id: "ch6.l6.e1",
                instruction: "Use s to replace * with the letter shown after //",
                initialText: "h*llo // e",
                initialCursorPosition: 1,
                expectedText: "hello // e",
                expectedCursorPosition: nil,
                hints: ["Move to *, press s, type the correct letter, press Esc"],
                difficulty: .learn,
                drillCount: 10,
                variations: [
                    .init(initialText: "w*rld // o", initialCursorPosition: 1,
                          expectedText: "world // o", expectedCursorPosition: nil),
                    .init(initialText: "c*de // o", initialCursorPosition: 1,
                          expectedText: "code // o", expectedCursorPosition: nil),
                    .init(initialText: "t*me // i", initialCursorPosition: 1,
                          expectedText: "time // i", expectedCursorPosition: nil),
                    .init(initialText: "l*ne // i", initialCursorPosition: 1,
                          expectedText: "line // i", expectedCursorPosition: nil),
                    .init(initialText: "m*ke // a", initialCursorPosition: 1,
                          expectedText: "make // a", expectedCursorPosition: nil),
                    .init(initialText: "f*le // i", initialCursorPosition: 1,
                          expectedText: "file // i", expectedCursorPosition: nil),
                    .init(initialText: "n*me // a", initialCursorPosition: 1,
                          expectedText: "name // a", expectedCursorPosition: nil),
                    .init(initialText: "s*ve // a", initialCursorPosition: 1,
                          expectedText: "save // a", expectedCursorPosition: nil),
                    .init(initialText: "d*ne // o", initialCursorPosition: 1,
                          expectedText: "done // o", expectedCursorPosition: nil),
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
            .text("R enters Replace mode — each character you type overwrites what's there. Press Esc to stop."),
            .spacer,
            .keyCommand(keys: ["R"], description: "Enter Replace mode"),
        ],
        exercises: [
            Exercise(
                id: "ch6.l7.e1",
                instruction: "Use R to overwrite *** with the text shown after //",
                initialText: "Value: *** // 123",
                initialCursorPosition: 7,
                expectedText: "Value: 123 // 123",
                expectedCursorPosition: nil,
                hints: ["Move to first *, press R, type 123, press Esc"],
                difficulty: .learn,
                drillCount: 10,
                variations: [
                    .init(initialText: "Set *** // abc", initialCursorPosition: 4,
                          expectedText: "Set abc // abc", expectedCursorPosition: nil),
                    .init(initialText: "Code: *** // 456", initialCursorPosition: 6,
                          expectedText: "Code: 456 // 456", expectedCursorPosition: nil),
                    .init(initialText: "PIN *** // 789", initialCursorPosition: 4,
                          expectedText: "PIN 789 // 789", expectedCursorPosition: nil),
                    .init(initialText: "Fix *** // end", initialCursorPosition: 4,
                          expectedText: "Fix end // end", expectedCursorPosition: nil),
                    .init(initialText: "Key: *** // xyz", initialCursorPosition: 5,
                          expectedText: "Key: xyz // xyz", expectedCursorPosition: nil),
                    .init(initialText: "ID: *** // 007", initialCursorPosition: 4,
                          expectedText: "ID: 007 // 007", expectedCursorPosition: nil),
                    .init(initialText: "Tag *** // vim", initialCursorPosition: 4,
                          expectedText: "Tag vim // vim", expectedCursorPosition: nil),
                    .init(initialText: "Use *** // new", initialCursorPosition: 4,
                          expectedText: "Use new // new", expectedCursorPosition: nil),
                    .init(initialText: "Old *** // top", initialCursorPosition: 4,
                          expectedText: "Old top // top", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["R"]
    )
}
