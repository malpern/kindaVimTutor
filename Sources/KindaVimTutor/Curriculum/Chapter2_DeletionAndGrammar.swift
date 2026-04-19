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
                initialText: "Keep this part DELETE ALL OF THIS",
                initialCursorPosition: 15,
                expectedText: "Keep this part ",
                expectedCursorPosition: nil,
                hints: ["Move to the first uppercase letter, then press D"],
                difficulty: .learn,
                drillCount: 10,
                variations: [
                    .init(initialText: "Good code stays BAD CODE GOES", initialCursorPosition: 16,
                          expectedText: "Good code stays ", expectedCursorPosition: nil),
                    .init(initialText: "First half lives REMOVE THIS", initialCursorPosition: 17,
                          expectedText: "First half lives ", expectedCursorPosition: nil),
                    .init(initialText: "Hello GOODBYE WORLD", initialCursorPosition: 6,
                          expectedText: "Hello ", expectedCursorPosition: nil),
                    .init(initialText: "Save DISCARD EVERYTHING", initialCursorPosition: 5,
                          expectedText: "Save ", expectedCursorPosition: nil),
                    .init(initialText: "Please JUNK JUNK JUNK", initialCursorPosition: 7,
                          expectedText: "Please ", expectedCursorPosition: nil),
                    .init(initialText: "OK NO NO NO NO", initialCursorPosition: 3,
                          expectedText: "OK ", expectedCursorPosition: nil),
                    .init(initialText: "Stay GO AWAY NOW", initialCursorPosition: 5,
                          expectedText: "Stay ", expectedCursorPosition: nil),
                    .init(initialText: "Correct WRONG WRONG", initialCursorPosition: 8,
                          expectedText: "Correct ", expectedCursorPosition: nil),
                    .init(initialText: "Yes NO DEFINITELY NOT", initialCursorPosition: 4,
                          expectedText: "Yes ", expectedCursorPosition: nil),
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
                initialText: "Fix BROKENNNN and continue.",
                initialCursorPosition: 4,
                expectedText: "Fix  and continue.",
                expectedCursorPosition: nil,
                hints: ["Move to the start of the uppercase word, then press de"],
                difficulty: .learn,
                drillCount: 10,
                variations: [
                    .init(initialText: "Remove BADDDDD from here.", initialCursorPosition: 7,
                          expectedText: "Remove  from here.", expectedCursorPosition: nil),
                    .init(initialText: "The WRONGGGG word here.", initialCursorPosition: 4,
                          expectedText: "The  word here.", expectedCursorPosition: nil),
                    .init(initialText: "Delete EXTRAAAA text.", initialCursorPosition: 7,
                          expectedText: "Delete  text.", expectedCursorPosition: nil),
                    .init(initialText: "Clean MESSYYY code.", initialCursorPosition: 6,
                          expectedText: "Clean  code.", expectedCursorPosition: nil),
                    .init(initialText: "Fix UGLYYYY style.", initialCursorPosition: 4,
                          expectedText: "Fix  style.", expectedCursorPosition: nil),
                    .init(initialText: "Erase OLDDDDD data.", initialCursorPosition: 6,
                          expectedText: "Erase  data.", expectedCursorPosition: nil),
                    .init(initialText: "Kill BUGGGGG now.", initialCursorPosition: 5,
                          expectedText: "Kill  now.", expectedCursorPosition: nil),
                    .init(initialText: "Drop JUNKKKK here.", initialCursorPosition: 5,
                          expectedText: "Drop  here.", expectedCursorPosition: nil),
                    .init(initialText: "Wipe STALEEE cache.", initialCursorPosition: 5,
                          expectedText: "Wipe  cache.", expectedCursorPosition: nil),
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
                initialText: "one two three * five six",
                initialCursorPosition: 0,
                expectedText: "one two three  five six",
                expectedCursorPosition: nil,
                hints: ["Type 3w to jump 3 words forward to the *, then x"],
                difficulty: .learn,
                drillCount: 10,
                variations: [
                    .init(initialText: "a b * d e f", initialCursorPosition: 0,
                          expectedText: "a b  d e f", expectedCursorPosition: nil),
                    .init(initialText: "skip skip skip skip * end", initialCursorPosition: 0,
                          expectedText: "skip skip skip skip  end", expectedCursorPosition: nil),
                    .init(initialText: "one * three four", initialCursorPosition: 0,
                          expectedText: "one  three four", expectedCursorPosition: nil),
                    .init(initialText: "a b c d e * g", initialCursorPosition: 0,
                          expectedText: "a b c d e  g", expectedCursorPosition: nil),
                    .init(initialText: "go go go go * stop", initialCursorPosition: 0,
                          expectedText: "go go go go  stop", expectedCursorPosition: nil),
                    .init(initialText: "x y z * end", initialCursorPosition: 0,
                          expectedText: "x y z  end", expectedCursorPosition: nil),
                    .init(initialText: "hop hop * done", initialCursorPosition: 0,
                          expectedText: "hop hop  done", expectedCursorPosition: nil),
                    .init(initialText: "step step step step step * fin", initialCursorPosition: 0,
                          expectedText: "step step step step step  fin", expectedCursorPosition: nil),
                    .init(initialText: "la la la * end", initialCursorPosition: 0,
                          expectedText: "la la la  end", expectedCursorPosition: nil),
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
                initialText: "Keep DELETE BOTH end.",
                initialCursorPosition: 5,
                expectedText: "Keep end.",
                expectedCursorPosition: nil,
                hints: ["Move to 'DELETE', then type d2w"],
                difficulty: .learn,
                drillCount: 10,
                variations: [
                    .init(initialText: "Good BAD UGLY text.", initialCursorPosition: 5,
                          expectedText: "Good text.", expectedCursorPosition: nil),
                    .init(initialText: "Save REMOVE THESE words.", initialCursorPosition: 5,
                          expectedText: "Save words.", expectedCursorPosition: nil),
                    .init(initialText: "Alpha GO AWAY Beta.", initialCursorPosition: 6,
                          expectedText: "Alpha Beta.", expectedCursorPosition: nil),
                    .init(initialText: "First EXTRA JUNK last.", initialCursorPosition: 6,
                          expectedText: "First last.", expectedCursorPosition: nil),
                    .init(initialText: "Yes NO WAY sure.", initialCursorPosition: 4,
                          expectedText: "Yes sure.", expectedCursorPosition: nil),
                    .init(initialText: "Start CUT THIS finish.", initialCursorPosition: 6,
                          expectedText: "Start finish.", expectedCursorPosition: nil),
                    .init(initialText: "Here DROP BOTH there.", initialCursorPosition: 5,
                          expectedText: "Here there.", expectedCursorPosition: nil),
                    .init(initialText: "One ERASE TWO three.", initialCursorPosition: 4,
                          expectedText: "One three.", expectedCursorPosition: nil),
                    .init(initialText: "Stay KILL THEM done.", initialCursorPosition: 5,
                          expectedText: "Stay done.", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["d2w", "2dd"]
    )
}
