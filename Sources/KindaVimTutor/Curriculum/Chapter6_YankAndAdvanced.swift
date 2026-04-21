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
                instruction: "Copy 'Hello ' with `yw`, move to end with `$`, paste with `p`",
                initialText: "\n\n\n// Go to start of line, yw then $ then p\nHello world\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 65,
                expectedText: "\n\n\n// Go to start of line, yw then $ then p\nHello worldHello \n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["At start of line press `yw`, then `$`, then `p`"],
                difficulty: .learn,
                drillCount: 6,
                variations: [
                    .init(initialText: "\n\n\n\n\n\n// Go to start of line, yw then $ then p\nBright sun\n\n\n\n\n\n\n", initialCursorPosition: 63, expectedText: "\n\n\n\n\n\n// Go to start of line, yw then $ then p\nBright sunBright \n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n// Go to start of line, yw then $ then p\nQuick fox\n\n\n\n", initialCursorPosition: 4, expectedText: "\n\n\n\n\n\n\n\n\n// Go to start of line, yw then $ then p\nQuick foxQuick \n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Go to start of line, yw then $ then p\nHappy tree\n\n", initialCursorPosition: 64, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Go to start of line, yw then $ then p\nHappy treeHappy \n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n// Go to start of line, yw then $ then p\nSilver moon\n\n\n\n\n\n\n\n", initialCursorPosition: 2, expectedText: "\n\n\n\n\n// Go to start of line, yw then $ then p\nSilver moonSilver \n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n\n// Go to start of line, yw then $ then p\nGolden ring\n", initialCursorPosition: 2, expectedText: "\n\n\n\n\n\n\n\n\n\n\n\n// Go to start of line, yw then $ then p\nGolden ringGolden \n", expectedCursorPosition: nil),
                ]
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
                instruction: "Duplicate the line: `yy` to copy, then `p` to paste below",
                initialText: "\n\n\n// Go to the line, yy then p to duplicate\nCopy me down\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 60,
                expectedText: "\n\n\n// Go to the line, yy then p to duplicate\nCopy me down\nCopy me down\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Go to the line, press `yy`, then `p`"],
                difficulty: .learn,
                drillCount: 6,
                variations: [
                    .init(initialText: "\n\n\n\n\n\n// Go to the line, yy then p to duplicate\nDuplicate this\n\n\n\n\n\n\n", initialCursorPosition: 69, expectedText: "\n\n\n\n\n\n// Go to the line, yy then p to duplicate\nDuplicate this\nDuplicate this\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n// Go to the line, yy then p to duplicate\nClone this line\n\n\n\n", initialCursorPosition: 0, expectedText: "\n\n\n\n\n\n\n\n\n// Go to the line, yy then p to duplicate\nClone this line\nClone this line\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Go to the line, yy then p to duplicate\nEcho me twice\n\n", initialCursorPosition: 8, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Go to the line, yy then p to duplicate\nEcho me twice\nEcho me twice\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n// Go to the line, yy then p to duplicate\nRepeat please\n\n\n\n\n\n\n\n", initialCursorPosition: 0, expectedText: "\n\n\n\n\n// Go to the line, yy then p to duplicate\nRepeat please\nRepeat please\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Go to the line, yy then p to duplicate\nYank and paste\n\n", initialCursorPosition: 9, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Go to the line, yy then p to duplicate\nYank and paste\nYank and paste\n\n", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["yy", "Y"],
        finderDrill: FinderDrillSpec(
            title: "Duplicate the treasure",
            subtitle: "Your Vim vocabulary works on files too. Press yy to copy the treasure, then p to paste a duplicate right next to it.",
            kind: .duplicate,
            // startIndex == targetIndex — student already on the
            // treasure; the work is entering yy + p.
            reps: [
                .init(startIndex: 5, targetIndex: 5),
                .init(startIndex: 2, targetIndex: 2),
                .init(startIndex: 11, targetIndex: 11),
            ]
        )
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
                instruction: "Toggle the lowercase word to UPPERCASE by pressing `~` repeatedly",
                initialText: "\n\n\n// Go to \"hello\", press ~ for each letter\nMake hello loud.\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 66,
                expectedText: "\n\n\n// Go to \"hello\", press ~ for each letter\nMake HELLO loud.\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Position on 'h', press `~` five times"],
                difficulty: .learn,
                drillCount: 6,
                variations: [
                    .init(initialText: "\n\n\n\n\n\n// Go to \"world\", press ~ for each letter\nSay world fast.\n\n\n\n\n\n\n", initialCursorPosition: 4, expectedText: "\n\n\n\n\n\n// Go to \"world\", press ~ for each letter\nSay WORLD fast.\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n// Go to \"power\", press ~ for each letter\nCall power up.\n\n\n\n", initialCursorPosition: 1, expectedText: "\n\n\n\n\n\n\n\n\n// Go to \"power\", press ~ for each letter\nCall POWER up.\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Go to \"quiet\", press ~ for each letter\nFind quiet room.\n\n", initialCursorPosition: 1, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Go to \"quiet\", press ~ for each letter\nFind QUIET room.\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n// Go to \"smart\", press ~ for each letter\nNote smart move.\n\n\n\n\n\n\n\n", initialCursorPosition: 67, expectedText: "\n\n\n\n\n// Go to \"smart\", press ~ for each letter\nNote SMART move.\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n\n// Go to \"clear\", press ~ for each letter\nUse clear text.\n", initialCursorPosition: 2, expectedText: "\n\n\n\n\n\n\n\n\n\n\n\n// Go to \"clear\", press ~ for each letter\nUse CLEAR text.\n", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["~"],
        externalTextDrill: ExternalTextDrillSpec(
            title: "~ in the Wild",
            subtitle: "Toggle case letter by letter in a real note. Position on the first letter of each lowercase word and press `~` until the word is UPPERCASE.",
            preferredApp: .notes,
            seedBody: "Make hello loud.\nSay world fast.\nCall power up.",
            reps: [
                .init(instruction: "Uppercase `hello` to `HELLO` with `~~~~~`",
                      predicate: .textContains("HELLO loud")),
                .init(instruction: "Uppercase `world` to `WORLD` with `~~~~~`",
                      predicate: .textContains("WORLD fast")),
                .init(instruction: "Uppercase `power` to `POWER` with `~~~~~`",
                      predicate: .textContains("POWER up")),
            ]
        )
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
                initialText: "\n\n\n// Go to the line, >> to indent it\nIndent me now\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 1,
                expectedText: "\n\n\n// Go to the line, >> to indent it\n    Indent me now\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Go to the line, then press >> to indent"],
                difficulty: .learn,
                drillCount: 6,
                variations: [
                    .init(initialText: "\n\n\n\n\n\n// Go to the line, >> to indent it\nShift this right\n\n\n\n\n\n\n", initialCursorPosition: 0, expectedText: "\n\n\n\n\n\n// Go to the line, >> to indent it\n    Shift this right\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n// Go to the line, >> to indent it\nPush me over\n\n\n\n", initialCursorPosition: 58, expectedText: "\n\n\n\n\n\n\n\n\n// Go to the line, >> to indent it\n    Push me over\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Go to the line, >> to indent it\nMove me please\n\n", initialCursorPosition: 1, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Go to the line, >> to indent it\n    Move me please\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n// Go to the line, >> to indent it\nIndent this line\n\n\n\n\n\n\n\n", initialCursorPosition: 58, expectedText: "\n\n\n\n\n// Go to the line, >> to indent it\n    Indent this line\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n\n// Go to the line, >> to indent it\nShift right one\n", initialCursorPosition: 3, expectedText: "\n\n\n\n\n\n\n\n\n\n\n\n// Go to the line, >> to indent it\n    Shift right one\n", expectedCursorPosition: nil),
                ]
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
                instruction: "Jump to the first line using `gg`, then delete the * with `x`",
                initialText: "* delete me\nLine two\nLine three\nLast\n\n\n// Press gg to jump to top, then x to delete *\n\n\n\n\n\n\n\n",
                initialCursorPosition: 37,
                expectedText: " delete me\nLine two\nLine three\nLast\n\n\n// Press gg to jump to top, then x to delete *\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Press `gg` to jump to top, then `x` to delete *"],
                difficulty: .learn,
                drillCount: 5,
                variations: [
                    .init(initialText: "* top star\nfoo\nbar\nbaz\n\n\n// Press gg to jump to top, then x to delete *\n\n\n\n\n\n\n\n", initialCursorPosition: 72, expectedText: " top star\nfoo\nbar\nbaz\n\n\n// Press gg to jump to top, then x to delete *\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "* first\nalpha\nbeta\ngamma\n\n\n// Press gg to jump to top, then x to delete *\n\n\n\n\n\n\n\n", initialCursorPosition: 74, expectedText: " first\nalpha\nbeta\ngamma\n\n\n// Press gg to jump to top, then x to delete *\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "* hit this\none\ntwo\nthree\n\n\n// Press gg to jump to top, then x to delete *\n\n\n\n\n\n\n\n", initialCursorPosition: 77, expectedText: " hit this\none\ntwo\nthree\n\n\n// Press gg to jump to top, then x to delete *\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "* target\nA\nB\nC\n\n\n// Press gg to jump to top, then x to delete *\n\n\n\n\n\n\n\n", initialCursorPosition: 16, expectedText: " target\nA\nB\nC\n\n\n// Press gg to jump to top, then x to delete *\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "* go up\nred\ngreen\nblue\n\n\n// Press gg to jump to top, then x to delete *\n\n\n\n\n\n\n\n", initialCursorPosition: 74, expectedText: " go up\nred\ngreen\nblue\n\n\n// Press gg to jump to top, then x to delete *\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
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
                instruction: "Use `s` to replace * with the letter shown after //",
                initialText: "\n\n\n// Go to *, press s, type e + Esc\nh*llo\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 48,
                expectedText: "\n\n\n// Go to *, press s, type e + Esc\nhello\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Move to *, press `s`, type the correct letter, press `Esc`"],
                difficulty: .learn,
                drillCount: 6,
                variations: [
                    .init(initialText: "\n\n\n\n\n\n// Go to *, press s, type o + Esc\nw*rld\n\n\n\n\n\n\n", initialCursorPosition: 51, expectedText: "\n\n\n\n\n\n// Go to *, press s, type o + Esc\nworld\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n// Go to *, press s, type o + Esc\nc*de\n\n\n\n", initialCursorPosition: 1, expectedText: "\n\n\n\n\n\n\n\n\n// Go to *, press s, type o + Esc\ncode\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Go to *, press s, type i + Esc\nt*me\n\n", initialCursorPosition: 4, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Go to *, press s, type i + Esc\ntime\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n// Go to *, press s, type a + Esc\nm*ke\n\n\n\n\n\n\n\n", initialCursorPosition: 0, expectedText: "\n\n\n\n\n// Go to *, press s, type a + Esc\nmake\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n\n// Go to *, press s, type i + Esc\nf*le\n", initialCursorPosition: 8, expectedText: "\n\n\n\n\n\n\n\n\n\n\n\n// Go to *, press s, type i + Esc\nfile\n", expectedCursorPosition: nil),
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
                instruction: "Use `R` to overwrite *** with the text shown after //",
                initialText: "\n\n\n// Go to first X, press R, type \"123\" + Esc\nValue: XXX\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 58,
                expectedText: "\n\n\n// Go to first X, press R, type \"123\" + Esc\nValue: 123\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Move to first *, press `R`, type 123, press `Esc`"],
                difficulty: .learn,
                drillCount: 6,
                variations: [
                    .init(initialText: "\n\n\n\n\n\n// Go to first X, press R, type \"abc\" + Esc\nCode: XXX\n\n\n\n\n\n\n", initialCursorPosition: 61, expectedText: "\n\n\n\n\n\n// Go to first X, press R, type \"abc\" + Esc\nCode: abc\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n// Go to first X, press R, type \"xyz\" + Esc\nKey: XXX\n\n\n\n", initialCursorPosition: 2, expectedText: "\n\n\n\n\n\n\n\n\n// Go to first X, press R, type \"xyz\" + Esc\nKey: xyz\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Go to first X, press R, type \"789\" + Esc\nPIN: XXX\n\n", initialCursorPosition: 6, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Go to first X, press R, type \"789\" + Esc\nPIN: 789\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n// Go to first X, press R, type \"red\" + Esc\nTag: XXX\n\n\n\n\n\n\n\n", initialCursorPosition: 62, expectedText: "\n\n\n\n\n// Go to first X, press R, type \"red\" + Esc\nTag: red\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n\n// Go to first X, press R, type \"007\" + Esc\nID: XXX\n", initialCursorPosition: 2, expectedText: "\n\n\n\n\n\n\n\n\n\n\n\n// Go to first X, press R, type \"007\" + Esc\nID: 007\n", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["R"]
    )
}
