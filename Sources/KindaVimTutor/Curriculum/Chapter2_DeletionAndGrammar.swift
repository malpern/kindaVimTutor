import Foundation

extension Curriculum {
    static let chapter2 = Chapter(
        id: "ch2",
        number: 2,
        title: "Deleting & The Vim Grammar",
        subtitle: "Operators, motions, and counts",
        systemImage: "scissors",
        lessons: [
            lesson2_1, lesson2_2, lesson2_3, lesson2_4, lesson2_5, lesson2_6,
        ]
    )

    // MARK: - Lesson 2.1: Delete Word

    private static let lesson2_1 = Lesson(
        id: "ch2.l1",
        number: 1,
        title: "Delete Word",
        subtitle: "Remove whole words with dw",
        explanation: [
            .heading("Delete From Cursor to Next Word"),
            .text("Deleting one character at a time with x is slow. Use dw to delete from the cursor to the start of the next word."),
            .spacer,
            .keyCommand(keys: ["d", "w"], description: "Delete to start of next word"),
            .spacer,
            .tip("Position your cursor at the beginning of the word you want to remove, then type dw."),
        ],
        exercises: [
            Exercise(
                id: "ch2.l1.e1",
                instruction: "Delete the UPPERCASE word using dw",
                initialText: "\n\n\n// Use w to reach the UPPERCASE word, then dw\nThe QUICK brown fox jumps\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 78,
                expectedText: "\n\n\n// Use w to reach the UPPERCASE word, then dw\nThe brown fox jumps\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Move to the start of the uppercase word, then press dw"],
                difficulty: .learn,
                drillCount: 10,
                variations: [
                    .init(initialText: "\n\n\n\n\n\n// Use w to reach the UPPERCASE word, then dw\nA BAD sentence shows up\n\n\n\n\n\n\n", initialCursorPosition: 2, expectedText: "\n\n\n\n\n\n// Use w to reach the UPPERCASE word, then dw\nA sentence shows up\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n// Use w to reach the UPPERCASE word, then dw\nThe UGLY result came back\n\n\n\n", initialCursorPosition: 0, expectedText: "\n\n\n\n\n\n\n\n\n// Use w to reach the UPPERCASE word, then dw\nThe result came back\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Use w to reach the UPPERCASE word, then dw\nOne LARGE gap was noted\n\n", initialCursorPosition: 3, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Use w to reach the UPPERCASE word, then dw\nOne gap was noted\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n// Use w to reach the UPPERCASE word, then dw\nFind EXTRA words to remove\n\n\n\n\n\n\n\n", initialCursorPosition: 3, expectedText: "\n\n\n\n\n// Use w to reach the UPPERCASE word, then dw\nFind words to remove\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n\n// Use w to reach the UPPERCASE word, then dw\nSpot LOUD noise on the line\n", initialCursorPosition: 9, expectedText: "\n\n\n\n\n\n\n\n\n\n\n\n// Use w to reach the UPPERCASE word, then dw\nSpot noise on the line\n", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["dw"]
    )

    // MARK: - Lesson 2.2: Delete to End of Line

    private static let lesson2_2 = Lesson(
        id: "ch2.l2",
        number: 2,
        title: "Delete to End of Line",
        subtitle: "Clean up with d$ and D",
        explanation: [
            .heading("Delete Everything After the Cursor"),
            .text("Use d$ to delete from the cursor position to the end of the line. D does the same thing — it's a shortcut."),
            .spacer,
            .keyCommand(keys: ["d", "$"], description: "Delete to end of line"),
            .keyCommand(keys: ["D"], description: "Same as d$ (shortcut)"),
        ],
        exercises: [
            Exercise(
                id: "ch2.l2.e1",
                instruction: "Delete from the uppercase word to the end of the line using D",
                initialText: "\n\n\n// Go to the UPPERCASE word, then D\nKeep this part DELETE ALL OF THIS\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 74,
                expectedText: "\n\n\n// Go to the UPPERCASE word, then D\nKeep this part \n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Move to the first uppercase letter, then press D"],
                difficulty: .learn,
                drillCount: 10,
                variations: [
                    .init(initialText: "\n\n\n\n\n\n// Go to the UPPERCASE word, then D\nGood code stays BAD CODE GOES\n\n\n\n\n\n\n", initialCursorPosition: 73, expectedText: "\n\n\n\n\n\n// Go to the UPPERCASE word, then D\nGood code stays \n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n// Go to the UPPERCASE word, then D\nFirst half lives REMOVE THIS\n\n\n\n", initialCursorPosition: 7, expectedText: "\n\n\n\n\n\n\n\n\n// Go to the UPPERCASE word, then D\nFirst half lives \n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Go to the UPPERCASE word, then D\nHello GOODBYE WORLD\n\n", initialCursorPosition: 3, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Go to the UPPERCASE word, then D\nHello \n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n// Go to the UPPERCASE word, then D\nSave DISCARD EVERYTHING\n\n\n\n\n\n\n\n\n", initialCursorPosition: 1, expectedText: "\n\n\n\n// Go to the UPPERCASE word, then D\nSave \n\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n// Go to the UPPERCASE word, then D\nPlease JUNK JUNK JUNK\n\n\n\n\n\n", initialCursorPosition: 0, expectedText: "\n\n\n\n\n\n\n// Go to the UPPERCASE word, then D\nPlease \n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n// Go to the UPPERCASE word, then D\nOK NO NO NO NO\n\n\n", initialCursorPosition: 6, expectedText: "\n\n\n\n\n\n\n\n\n\n// Go to the UPPERCASE word, then D\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n\n// Go to the UPPERCASE word, then D\nStay GO AWAY NOW\n", initialCursorPosition: 10, expectedText: "\n\n\n\n\n\n\n\n\n\n\n\n// Go to the UPPERCASE word, then D\nStay \n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n// Go to the UPPERCASE word, then D\nCorrect WRONG WRONG\n\n\n\n\n\n\n\n", initialCursorPosition: 68, expectedText: "\n\n\n\n\n// Go to the UPPERCASE word, then D\nCorrect \n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n// Go to the UPPERCASE word, then D\nYes NO DEFINITELY NOT\n\n\n\n\n", initialCursorPosition: 66, expectedText: "\n\n\n\n\n\n\n\n// Go to the UPPERCASE word, then D\nYes \n\n\n\n\n", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["d$", "D"]
    )

    // MARK: - Lesson 2.3: Delete Entire Line

    private static let lesson2_3 = Lesson(
        id: "ch2.l3",
        number: 3,
        title: "Delete Entire Line",
        subtitle: "Remove whole lines with dd",
        explanation: [
            .heading("Delete the Whole Line"),
            .text("Press dd to delete the entire line the cursor is on. The lines below move up to fill the gap."),
            .spacer,
            .keyCommand(keys: ["d", "d"], description: "Delete entire current line"),
            .spacer,
            .text("This is one of the most commonly used Vim commands."),
        ],
        exercises: [
            Exercise(
                id: "ch2.l3.e1",
                instruction: "Delete the line marked DELETE using dd",
                initialText: "\n\n\n// Use j to reach the DELETE line, then dd\nLine one stays put\n// DELETE this line\nLine three stays put\n\n\n\n\n\n\n\n",
                initialCursorPosition: 2,
                expectedText: "\n\n\n// Use j to reach the DELETE line, then dd\nLine one stays put\nLine three stays put\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Move to the marked line with j, then press dd"],
                difficulty: .learn,
                drillCount: 10,
                variations: [
                    .init(initialText: "\n\n\n\n\n\n// Use j to reach the DELETE line, then dd\nLine one stays put\n// DELETE this line\nLine three stays put\n\n\n\n\n", initialCursorPosition: 112, expectedText: "\n\n\n\n\n\n// Use j to reach the DELETE line, then dd\nLine one stays put\nLine three stays put\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n// Use j to reach the DELETE line, then dd\nLine one stays put\n// DELETE this line\nLine three stays put\n\n", initialCursorPosition: 2, expectedText: "\n\n\n\n\n\n\n\n\n// Use j to reach the DELETE line, then dd\nLine one stays put\nLine three stays put\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n// Use j to reach the DELETE line, then dd\nLine one stays put\n// DELETE this line\nLine three stays put\n\n\n\n\n\n", initialCursorPosition: 110, expectedText: "\n\n\n\n\n// Use j to reach the DELETE line, then dd\nLine one stays put\nLine three stays put\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Use j to reach the DELETE line, then dd\nLine one stays put\n// DELETE this line\nLine three stays put", initialCursorPosition: 0, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Use j to reach the DELETE line, then dd\nLine one stays put\nLine three stays put", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["dd"]
    )

    // MARK: - Lesson 2.4: The Vim Grammar

    private static let lesson2_4 = Lesson(
        id: "ch2.l4",
        number: 4,
        title: "The Vim Grammar",
        subtitle: "Operator + Motion = Command",
        explanation: [
            .heading("The Most Important Concept in Vim"),
            .text("Vim commands follow a grammar: an operator (what to do) followed by a motion (where to do it)."),
            .spacer,
            .text("You already know this! dw = delete + word. d$ = delete + end-of-line. Every motion you learn multiplies every operator you know:"),
            .keyCommand(keys: ["d", "e"], description: "Delete to end of word"),
            .keyCommand(keys: ["d", "0"], description: "Delete to start of line"),
            .keyCommand(keys: ["d", "G"], description: "Delete to end of file"),
            .spacer,
            .tip("This grammar is why Vim is so powerful. A few operators times a few motions gives you dozens of commands."),
        ],
        exercises: [
            Exercise(
                id: "ch2.l4.e1",
                instruction: "Use de to delete from cursor to end of the UPPERCASE word",
                initialText: "\n\n\n// Go to the UPPERCASE word, then de (stops at word end)\nKeep the EXTRA bits here\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 94,
                expectedText: "\n\n\n// Go to the UPPERCASE word, then de (stops at word end)\nKeep the  bits here\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Move to the start of the uppercase word, then press de"],
                difficulty: .learn,
                drillCount: 10,
                variations: [
                    .init(initialText: "\n\n\n\n\n\n// Go to the UPPERCASE word, then de (stops at word end)\nRead LOUD part again soon\n\n\n\n\n\n\n", initialCursorPosition: 93, expectedText: "\n\n\n\n\n\n// Go to the UPPERCASE word, then de (stops at word end)\nRead  part again soon\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n// Go to the UPPERCASE word, then de (stops at word end)\nSome BIG thing stays put\n\n\n\n", initialCursorPosition: 8, expectedText: "\n\n\n\n\n\n\n\n\n// Go to the UPPERCASE word, then de (stops at word end)\nSome  thing stays put\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Go to the UPPERCASE word, then de (stops at word end)\nOur UGLY stone fell down\n\n", initialCursorPosition: 2, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Go to the UPPERCASE word, then de (stops at word end)\nOur  stone fell down\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n// Go to the UPPERCASE word, then de (stops at word end)\nSee the UGLY mark on wall\n\n\n\n\n\n\n\n", initialCursorPosition: 90, expectedText: "\n\n\n\n\n// Go to the UPPERCASE word, then de (stops at word end)\nSee the  mark on wall\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n\n// Go to the UPPERCASE word, then de (stops at word end)\nThis BAD apple rots fast\n", initialCursorPosition: 2, expectedText: "\n\n\n\n\n\n\n\n\n\n\n\n// Go to the UPPERCASE word, then de (stops at word end)\nThis  apple rots fast\n", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["de", "d0", "dG", "dgg"]
    )

    // MARK: - Lesson 2.5: Counts with Motions

    private static let lesson2_5 = Lesson(
        id: "ch2.l5",
        number: 5,
        title: "Counts with Motions",
        subtitle: "Move faster with 2w, 3j, 4l",
        explanation: [
            .heading("Repeat a Motion Multiple Times"),
            .text("Type a number before a motion to repeat it that many times:"),
            .spacer,
            .keyCommand(keys: ["2", "w"], description: "Move forward 2 words"),
            .keyCommand(keys: ["3", "j"], description: "Move down 3 lines"),
            .spacer,
            .text("Instead of pressing w three times, just type 3w."),
            .tip("You can use counts with any motion: 5j, 10l, 2b — the number always goes first."),
        ],
        exercises: [
            Exercise(
                id: "ch2.l5.e1",
                instruction: "Use a count + w to jump directly to the * and delete it with x",
                initialText: "\n\n\n// Use a count + w (e.g. 3w) to reach *, then x\none two * three four\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 0,
                expectedText: "\n\n\n// Use a count + w (e.g. 3w) to reach *, then x\none two  three four\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Type 3w to jump 3 words forward to the *, then x"],
                difficulty: .learn,
                drillCount: 10,
                variations: [
                    .init(initialText: "\n\n\n\n\n\n// Use a count + w (e.g. 3w) to reach *, then x\nred blue green * yellow\n\n\n\n\n\n\n", initialCursorPosition: 1, expectedText: "\n\n\n\n\n\n// Use a count + w (e.g. 3w) to reach *, then x\nred blue green  yellow\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n// Use a count + w (e.g. 3w) to reach *, then x\na b c * d e\n\n\n\n", initialCursorPosition: 72, expectedText: "\n\n\n\n\n\n\n\n\n// Use a count + w (e.g. 3w) to reach *, then x\na b c  d e\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Use a count + w (e.g. 3w) to reach *, then x\nup down left * right\n\n", initialCursorPosition: 1, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Use a count + w (e.g. 3w) to reach *, then x\nup down left  right\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n// Use a count + w (e.g. 3w) to reach *, then x\napple pear plum * fig\n\n\n\n\n\n\n\n", initialCursorPosition: 76, expectedText: "\n\n\n\n\n// Use a count + w (e.g. 3w) to reach *, then x\napple pear plum  fig\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n\n// Use a count + w (e.g. 3w) to reach *, then x\nhi there * end\n", initialCursorPosition: 6, expectedText: "\n\n\n\n\n\n\n\n\n\n\n\n// Use a count + w (e.g. 3w) to reach *, then x\nhi there  end\n", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["2w", "3j"]
    )

    // MARK: - Lesson 2.6: Counts with Operators

    private static let lesson2_6 = Lesson(
        id: "ch2.l6",
        number: 6,
        title: "Counts with Operators",
        subtitle: "Delete more with d2w, 2dd",
        explanation: [
            .heading("Combine Counts with Operators"),
            .text("Counts work with operator-motion combinations too:"),
            .spacer,
            .keyCommand(keys: ["d", "2", "w"], description: "Delete 2 words"),
            .keyCommand(keys: ["2", "d", "d"], description: "Delete 2 lines"),
            .spacer,
            .text("The full Vim grammar is: [count] operator [count] motion."),
        ],
        exercises: [
            Exercise(
                id: "ch2.l6.e1",
                instruction: "Use d2w to delete the two UPPERCASE words",
                initialText: "\n\n\n// Navigate to the first UPPERCASE word, then d2w\nSome BAD LOUD words here\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 84,
                expectedText: "\n\n\n// Navigate to the first UPPERCASE word, then d2w\nSome words here\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Move to 'DELETE', then type d2w"],
                difficulty: .learn,
                drillCount: 10,
                variations: [
                    .init(initialText: "\n\n\n\n\n\n// Navigate to the first UPPERCASE word, then d2w\nA UGLY NASTY thing lives\n\n\n\n\n\n\n", initialCursorPosition: 81, expectedText: "\n\n\n\n\n\n// Navigate to the first UPPERCASE word, then d2w\nA thing lives\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n// Navigate to the first UPPERCASE word, then d2w\nOur FAST BIG train runs\n\n\n\n", initialCursorPosition: 8, expectedText: "\n\n\n\n\n\n\n\n\n// Navigate to the first UPPERCASE word, then d2w\nOur train runs\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Navigate to the first UPPERCASE word, then d2w\nGo FAR AWAY now please\n\n", initialCursorPosition: 0, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Navigate to the first UPPERCASE word, then d2w\nGo now please\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n// Navigate to the first UPPERCASE word, then d2w\nSay LOUD NOISY words today\n\n\n\n\n\n\n\n", initialCursorPosition: 2, expectedText: "\n\n\n\n\n// Navigate to the first UPPERCASE word, then d2w\nSay words today\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n\n// Navigate to the first UPPERCASE word, then d2w\nOne HUGE HEAVY stone fell\n", initialCursorPosition: 2, expectedText: "\n\n\n\n\n\n\n\n\n\n\n\n// Navigate to the first UPPERCASE word, then d2w\nOne stone fell\n", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["d2w", "2dd"]
    )
}
