import Foundation

extension Curriculum {
    static let chapter0 = Chapter(
        id: "ch0",
        number: 0,
        title: "Setup",
        subtitle: "Install kindaVim, then head to Chapter 1",
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
        subtitle: "What it is and how to install it",
        explanation: [
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
            .spacer,
            .tip("Once kindaVim is installed and running, head to Chapter 1 — the first lesson introduces the two modes you'll use constantly."),
        ],
        exercises: [],
        motionsIntroduced: []
    )
}
