import Foundation

extension Curriculum {
    static let chapter0 = Chapter(
        id: "ch0",
        number: 0,
        title: "Setup",
        subtitle: "Install kindaVim and meet its modes",
        systemImage: "wrench.and.screwdriver",
        lessons: [
            lesson0_1,
        ]
    )

    // MARK: - Lesson 0.1: Meet kindaVim

    private static let lesson0_1 = Lesson(
        id: "ch0.l1",
        number: 1,
        title: "Meet kindaVim",
        subtitle: "What it is and how to use it",
        explanation: [
            // Page 1: What is kindaVim + install
            .heading("Meet kindaVim"),
            .image(assetName: "kindaVimLogo", size: 120),
            .spacer,
            .text("kindaVim brings Vim motions to every macOS text field — Xcode, Safari, Mail, Messages, anywhere you can type. This tutor teaches those motions by driving kindaVim underneath."),
            .spacer,
            .kindaVimInstallStatus,
            .spacer,
            .linkTip(
                sfSymbol: "play.rectangle.fill",
                accent: .youtube,
                label: "Watch the DevOps Toolkit kindaVim tutorial (12:40) on YouTube",
                url: "https://www.youtube.com/watch?v=4NpE8q_bLcM"
            ),

            // Page 2: Modes
            .heading("Normal, Insert, Visual"),
            .text("Vim's superpower is having different modes for different jobs. You don't type text and move cursor with the same keys — you flip modes."),
            .spacer,
            .keyCommand(keys: ["Esc"], description: "Switch to Normal mode (motions, operators)"),
            .keyCommand(keys: ["i"], description: "Switch to Insert mode (type text)"),
            .keyCommand(keys: ["v"], description: "Switch to Visual mode (select text)"),
            .spacer,
            .modeFlowNarrative,
            .spacer,
            .text("You'll spend most of your time in Normal mode, dipping into Insert only to type new text."),
            .spacer,
            .heading("The Mode Chip"),
            .text("Look at the top-right of this window — that colored chip is your live kindaVim mode indicator. It updates the moment you switch modes:"),
            .spacer,
            .modePreview(.insert, caption: "Blue INSERT — you're typing, keys produce letters."),
            .modePreview(.normal, caption: "Green NORMAL — keys are motions and operators."),
            .modePreview(.visual, caption: "Purple VISUAL — you're selecting a range."),
            .spacer,
            .tip("If the chip shows CLICK TO BEGIN, kindaVim hasn't picked up a text field yet. Click into any text field on your Mac and the chip will flip to INSERT."),
        ],
        exercises: [],
        motionsIntroduced: []
    )
}
