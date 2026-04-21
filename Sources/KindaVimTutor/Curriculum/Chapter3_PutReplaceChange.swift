import Foundation

extension Curriculum {
    static let chapter3 = Chapter(
        id: "ch3",
        number: 3,
        title: "Put, Replace, Change",
        subtitle: "Rearrange and transform text",
        systemImage: "arrow.triangle.swap",
        lessons: [
            lesson3_1, lesson3_2, lesson3_3, lesson3_4, lesson3_5,
        ]
    )

    // MARK: - Lesson 3.1: Put (Paste)

    private static let lesson3_1 = Lesson(
        id: "ch3.l1",
        number: 1,
        title: "Put (Paste)",
        subtitle: "Paste deleted text with p",
        explanation: [
            .heading("What You Delete, You Can Put Back"),
            .text("When you delete text with d or dd, Vim remembers it. Press p to put (paste) it after the cursor, or P to put it before."),
            .spacer,
            .keyCommand(keys: ["p"], description: "Put (paste) after cursor"),
            .keyCommand(keys: ["P"], description: "Put (paste) before cursor"),
            .spacer,
            .tip("Delete a line with dd, move to where you want it, press p. That's how you move lines around."),
        ],
        exercises: [
            Exercise(
                id: "ch3.l1.e1",
                instruction: "Swap the lines: delete line B with `dd`, move down, paste with `p`",
                initialText: "\n\n\n// Reorder: dd the out-of-order line, move, then p\nA) First\nC) Third\nB) Second\nD) Fourth\n\n\n\n\n\n\n",
                initialCursorPosition: 96,
                expectedText: "\n\n\n// Reorder: dd the out-of-order line, move, then p\nA) First\nB) Second\nC) Third\nD) Fourth\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["On the out-of-order line, press `dd`, move to the correct spot, press `p`"],
                difficulty: .learn,
                drillCount: 6,
                variations: [
                    .init(initialText: "\n\n\n\n\n\n// Reorder: dd the out-of-order line, move, then p\n1. Wake\n3. Work\n2. Eat\n4. Sleep\n\n\n\n", initialCursorPosition: 4, expectedText: "\n\n\n\n\n\n// Reorder: dd the out-of-order line, move, then p\n1. Wake\n2. Eat\n3. Work\n4. Sleep\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n// Reorder: dd the out-of-order line, move, then p\nred\nblue\ngreen\nyellow\n", initialCursorPosition: 8, expectedText: "\n\n\n\n\n\n\n\n\n// Reorder: dd the out-of-order line, move, then p\nred\ngreen\nblue\nyellow\n", expectedCursorPosition: nil),
                    .init(initialText: "\n// Reorder: dd the out-of-order line, move, then p\none\nthree\ntwo\nfour\n\n\n\n\n\n\n\n\n", initialCursorPosition: 72, expectedText: "\n// Reorder: dd the out-of-order line, move, then p\none\ntwo\nthree\nfour\n\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n// Reorder: dd the out-of-order line, move, then p\nAlpha\nGamma\nBeta\nDelta\n\n\n\n\n", initialCursorPosition: 81, expectedText: "\n\n\n\n\n// Reorder: dd the out-of-order line, move, then p\nAlpha\nBeta\nGamma\nDelta\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n// Reorder: dd the out-of-order line, move, then p\ncat\nmouse\ndog\nfish\n\n", initialCursorPosition: 2, expectedText: "\n\n\n\n\n\n\n\n// Reorder: dd the out-of-order line, move, then p\ncat\ndog\nmouse\nfish\n\n", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["p", "P"],
        externalTextDrill: ExternalTextDrillSpec(
            title: "p in the Wild",
            subtitle: "Reorder lines in a real Mail draft. Delete the out-of-order line with `dd`, move to where it belongs, then `p` to put it back.",
            preferredApp: .mail,
            seedBody: "1. Wake\n3. Work\n2. Eat\n4. Sleep",
            reps: [
                .init(instruction: "Move `2. Eat` above `3. Work` using `dd` + `p` (or `P`)",
                      predicate: .textContains("1. Wake\n2. Eat\n3. Work\n4. Sleep")),
            ]
        )
    )

    // MARK: - Lesson 3.2: Replace Character

    private static let lesson3_2 = Lesson(
        id: "ch3.l2",
        number: 2,
        title: "Replace Character",
        subtitle: "Fix single characters with r",
        explanation: [
            .heading("Replace Without Entering Insert Mode"),
            .text("Press r followed by a character to replace the character under the cursor. You stay in Normal mode."),
            .spacer,
            .keyCommand(keys: ["r", "x"], description: "Replace character under cursor with x"),
            .spacer,
            .tip("r is perfect for fixing single-character typos: navigate to it, press r, type the correction."),
        ],
        exercises: [
            Exercise(
                id: "ch3.l2.e1",
                instruction: "Fix the wrong letter using `r` — change * to the correct character shown after //",
                initialText: "\n\n\n// Navigate to the *, then ra\nThe c*t sat on a mat\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 55,
                expectedText: "\n\n\n// Navigate to the *, then ra\nThe cat sat on a mat\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Move to *, press `r`, then type the letter shown after //"],
                difficulty: .learn,
                drillCount: 6,
                variations: [
                    .init(initialText: "\n\n\n\n\n\n// Navigate to the *, then ra\nWe r*n fast to home\n\n\n\n\n\n\n", initialCursorPosition: 3, expectedText: "\n\n\n\n\n\n// Navigate to the *, then ra\nWe ran fast to home\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n// Navigate to the *, then rr\nA fi*e alarm rang loud\n\n\n\n", initialCursorPosition: 6, expectedText: "\n\n\n\n\n\n\n\n\n// Navigate to the *, then rr\nA fire alarm rang loud\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Navigate to the *, then ra\nThis pl*ce has a map\n\n", initialCursorPosition: 2, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Navigate to the *, then ra\nThis place has a map\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n// Navigate to the *, then ra\nLet me w*lk there now\n\n\n\n\n\n\n\n", initialCursorPosition: 1, expectedText: "\n\n\n\n\n// Navigate to the *, then ra\nLet me walk there now\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n\n// Navigate to the *, then rt\nThe lit*le box is here\n", initialCursorPosition: 2, expectedText: "\n\n\n\n\n\n\n\n\n\n\n\n// Navigate to the *, then rt\nThe little box is here\n", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["r"]
    )

    // MARK: - Lesson 3.3: Change Word

    private static let lesson3_3 = Lesson(
        id: "ch3.l3",
        number: 3,
        title: "Change Word",
        subtitle: "Delete and replace with ce",
        explanation: [
            .heading("Delete and Start Typing"),
            .text("The change operator c works like d, but drops you into Insert mode to type the replacement."),
            .spacer,
            .keyCommand(keys: ["c", "e"], description: "Change to end of word (delete + insert)"),
            .spacer,
            .tip("Think of c as \"change\" — delete the target, then immediately type what goes there instead."),
        ],
        exercises: [
            Exercise(
                id: "ch3.l3.e1",
                instruction: "Change the WRONG word to RIGHT using `ce`",
                initialText: "\n\n\n// Go to UPPERCASE, cw then type \"new\" + Esc\nSet OLD value now please\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 2,
                expectedText: "\n\n\n// Go to UPPERCASE, cw then type \"new\" + Esc\nSet new value now please\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Move to WRONG, press `ce`, type RIGHT, press `Esc`"],
                difficulty: .learn,
                drillCount: 6,
                variations: [
                    .init(initialText: "\n\n\n\n\n\n// Go to UPPERCASE, cw then type \"right\" + Esc\nThe WRONG answer stood out\n\n\n\n\n\n\n", initialCursorPosition: 85, expectedText: "\n\n\n\n\n\n// Go to UPPERCASE, cw then type \"right\" + Esc\nThe right answer stood out\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n// Go to UPPERCASE, cw then type \"good\" + Esc\nA BAD choice was made\n\n\n\n", initialCursorPosition: 80, expectedText: "\n\n\n\n\n\n\n\n\n// Go to UPPERCASE, cw then type \"good\" + Esc\nA good choice was made\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Go to UPPERCASE, cw then type \"warm\" + Esc\nUse COLD water to rinse\n\n", initialCursorPosition: 0, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Go to UPPERCASE, cw then type \"warm\" + Esc\nUse warm water to rinse\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n// Go to UPPERCASE, cw then type \"clean\" + Esc\nFind LOST keys in pocket\n\n\n\n\n\n\n\n", initialCursorPosition: 81, expectedText: "\n\n\n\n\n// Go to UPPERCASE, cw then type \"clean\" + Esc\nFind clean keys in pocket\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n\n// Go to UPPERCASE, cw then type \"fixed\" + Esc\nMark BROKEN items for repair\n", initialCursorPosition: 88, expectedText: "\n\n\n\n\n\n\n\n\n\n\n\n// Go to UPPERCASE, cw then type \"fixed\" + Esc\nMark fixed items for repair\n", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["ce", "cw"],
        externalTextDrill: ExternalTextDrillSpec(
            title: "cw in the Wild",
            subtitle: "Change whole words in a real note. `cw` deletes the word and drops you into insert mode to type the replacement.",
            preferredApp: .notes,
            seedBody: "The DOG ran fast\nThe CAT slept late\nThe BIRD sang loud",
            reps: [
                .init(instruction: "Change `DOG` to `fox` with `cw fox` + `Esc`",
                      predicate: .textContains("fox ran")),
                .init(instruction: "Change `CAT` to `owl` with `cw owl` + `Esc`",
                      predicate: .textContains("owl slept")),
                .init(instruction: "Change `BIRD` to `wolf` with `cw wolf` + `Esc`",
                      predicate: .textContains("wolf sang")),
            ]
        )
    )

    // MARK: - Lesson 3.4: Change to End of Line

    private static let lesson3_4 = Lesson(
        id: "ch3.l4",
        number: 4,
        title: "Change to End of Line",
        subtitle: "Rewrite the rest with C",
        explanation: [
            .heading("Replace Everything After the Cursor"),
            .text("C (or c$) deletes from the cursor to the end of the line and puts you in Insert mode."),
            .spacer,
            .keyCommand(keys: ["C"], description: "Change to end of line"),
            .spacer,
            .text("Useful when the end of a line is wrong and you want to retype it."),
        ],
        exercises: [
            Exercise(
                id: "ch3.l4.e1",
                instruction: "Use `C` to replace everything after | with the text shown in // comment",
                initialText: "\n\n\n// Go to |, C then type \"good end\" + Esc\nGood start |XXXXX\n\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 69,
                expectedText: "\n\n\n// Go to |, C then type \"good end\" + Esc\nGood start good end\n\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["Move to |, press `C`, type what the // comment says, press `Esc`"],
                difficulty: .learn,
                drillCount: 6,
                variations: [
                    .init(initialText: "\n\n\n\n\n\n// Go to |, C then type \"is clear now\" + Esc\nThe path |YYYYYYY\n\n\n\n\n\n\n", initialCursorPosition: 1, expectedText: "\n\n\n\n\n\n// Go to |, C then type \"is clear now\" + Esc\nThe path is clear now\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n// Go to |, C then type \"go home soon\" + Esc\nI will |ZZZZZZZZZ\n\n\n\n", initialCursorPosition: 8, expectedText: "\n\n\n\n\n\n\n\n\n// Go to |, C then type \"go home soon\" + Esc\nI will go home soon\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// Go to |, C then type \"worked well\" + Esc\nHer plan |WWWWWWWW\n\n", initialCursorPosition: 1, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// Go to |, C then type \"worked well\" + Esc\nHer plan worked well\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n// Go to |, C then type \"turned blue\" + Esc\nThe sky |VVVVVVV\n\n\n\n\n\n\n\n", initialCursorPosition: 68, expectedText: "\n\n\n\n\n// Go to |, C then type \"turned blue\" + Esc\nThe sky turned blue\n\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n\n// Go to |, C then type \"runs fast\" + Esc\nMy code |UUUUUUU\n", initialCursorPosition: 7, expectedText: "\n\n\n\n\n\n\n\n\n\n\n\n// Go to |, C then type \"runs fast\" + Esc\nMy code runs fast\n", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["c$", "C"],
        externalTextDrill: ExternalTextDrillSpec(
            title: "C in the Wild",
            subtitle: "Use **C** to rewrite the end of each line. Position the cursor where the new text should start, press `C`, type the replacement, `Esc`.",
            preferredApp: .notes,
            seedBody: "Good start XXXXXXX\nThe path YYYYYYY\nMy code UUUUUUU",
            reps: [
                .init(instruction: "On line 1, put the cursor on `XXXXXXX` and change it to `end here` with `C`",
                      predicate: .textContains("Good start end here")),
                .init(instruction: "On line 2, put the cursor on `YYYYYYY` and change it to `is clear` with `C`",
                      predicate: .textContains("The path is clear")),
                .init(instruction: "On line 3, put the cursor on `UUUUUUU` and change it to `runs fast` with `C`",
                      predicate: .textContains("My code runs fast")),
            ]
        )
    )

    // MARK: - Lesson 3.5: Open Lines

    private static let lesson3_5 = Lesson(
        id: "ch3.l5",
        number: 5,
        title: "Open Lines",
        subtitle: "Create new lines with o and O",
        explanation: [
            .heading("Insert a New Line"),
            .text("Press o to open a new line below and enter Insert mode. Press O to open above."),
            .spacer,
            .keyCommand(keys: ["o"], description: "Open line below"),
            .keyCommand(keys: ["O"], description: "Open line above"),
            .spacer,
            .tip("o is one of the most common ways to start typing. Much faster than going to end of line and pressing Enter."),
        ],
        exercises: [
            Exercise(
                id: "ch3.l5.e1",
                instruction: "Add 'Line two' between the lines using `o`",
                initialText: "\n\n\n// On \"Line one\", press o, type \"Line two\" + Esc\nLine one\nLine three\n\n\n\n\n\n\n\n\n",
                initialCursorPosition: 78,
                expectedText: "\n\n\n// On \"Line one\", press o, type \"Line two\" + Esc\nLine one\nLine two\nLine three\n\n\n\n\n\n\n\n\n",
                expectedCursorPosition: nil,
                hints: ["On the upper line, press `o`, type the new line, press `Esc`"],
                difficulty: .learn,
                drillCount: 6,
                variations: [
                    .init(initialText: "\n\n\n\n\n\n// On \"First part\", press o, type \"Second part\" + Esc\nFirst part\nThird part\n\n\n\n\n\n", initialCursorPosition: 82, expectedText: "\n\n\n\n\n\n// On \"First part\", press o, type \"Second part\" + Esc\nFirst part\nSecond part\nThird part\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n// On \"Step 1\", press o, type \"Step 2\" + Esc\nStep 1\nStep 3\n\n\n", initialCursorPosition: 4, expectedText: "\n\n\n\n\n\n\n\n\n// On \"Step 1\", press o, type \"Step 2\" + Esc\nStep 1\nStep 2\nStep 3\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n// On \"Morning\", press o, type \"Afternoon\" + Esc\nMorning\nEvening\n", initialCursorPosition: 0, expectedText: "\n\n\n\n\n\n\n\n\n\n\n// On \"Morning\", press o, type \"Afternoon\" + Esc\nMorning\nAfternoon\nEvening\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n// On \"Chapter A\", press o, type \"Chapter B\" + Esc\nChapter A\nChapter C\n\n\n\n\n\n\n", initialCursorPosition: 82, expectedText: "\n\n\n\n\n// On \"Chapter A\", press o, type \"Chapter B\" + Esc\nChapter A\nChapter B\nChapter C\n\n\n\n\n\n\n", expectedCursorPosition: nil),
                    .init(initialText: "\n\n\n\n\n\n\n\n\n\n\n\n// On \"red\", press o, type \"orange\" + Esc\nred\ngreen", initialCursorPosition: 10, expectedText: "\n\n\n\n\n\n\n\n\n\n\n\n// On \"red\", press o, type \"orange\" + Esc\nred\norange\ngreen", expectedCursorPosition: nil),
                ]
            ),
        ],
        motionsIntroduced: ["o", "O"]
    )
}
