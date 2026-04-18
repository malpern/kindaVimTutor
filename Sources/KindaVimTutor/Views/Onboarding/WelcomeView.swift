import SwiftUI

struct WelcomeView: View {
    var onStartLearning: (() -> Void)?

    @State private var showLogo = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showHint = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                logo
                    .frame(width: 140, height: 140)
                    .opacity(showLogo ? 1 : 0)
                    .scaleEffect(showLogo ? 1 : 0.9)
                    .animation(.spring(duration: 0.55, bounce: 0.22), value: showLogo)

                Text("kindaVim Tutor")
                    .font(.system(size: 44, weight: .bold))
                    .tracking(-1.2)
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : 8)
                    .animation(.spring(duration: 0.6, bounce: 0.0), value: showTitle)

                Text("Learn Vim motions for macOS,\none exercise at a time.")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.secondary)
                    .tracking(-0.3)
                    .multilineTextAlignment(.center)
                    .opacity(showSubtitle ? 1 : 0)
                    .offset(y: showSubtitle ? 0 : 6)
                    .animation(.spring(duration: 0.5, bounce: 0.0), value: showSubtitle)
            }

            Spacer()

            VStack(spacing: 16) {
                AdvanceHintView("press to begin")

                kindaVimStatus
            }
            .padding(.bottom, 40)
            .opacity(showHint ? 1 : 0)
            .animation(.easeOut(duration: 0.4), value: showHint)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .focusable()
        .accessibilityIdentifier("WelcomeScreen")
        .accessibilityLabel("welcome lesson=none")
        .onKeyPress { keyPress in
            if keyPress.characters.first == "]" || keyPress.characters.first == " " {
                onStartLearning?()
                return .handled
            }
            return .ignored
        }
        .task {
            try? await Task.sleep(for: .milliseconds(60))
            showLogo = true
            try? await Task.sleep(for: .milliseconds(180))
            showTitle = true
            try? await Task.sleep(for: .milliseconds(200))
            showSubtitle = true
            try? await Task.sleep(for: .milliseconds(300))
            showHint = true
        }
    }

    @ViewBuilder
    private var logo: some View {
        if let url = Bundle.module.url(forResource: "kindaVimLogo", withExtension: "png"),
           let ns = NSImage(contentsOf: url) {
            Image(nsImage: ns)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .shadow(color: .black.opacity(0.35), radius: 18, y: 5)
        } else {
            Image(systemName: "photo")
        }
    }

    private var kindaVimStatus: some View {
        HStack(spacing: 6) {
            let isRunning = !NSRunningApplication.runningApplications(
                withBundleIdentifier: "mo.com.sleeplessmind.kindaVim"
            ).isEmpty

            if isRunning {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.quaternary)
                Text("kindaVim is running")
                    .font(.system(size: 13))
                    .foregroundStyle(.quaternary)
            } else {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
                Text("kindaVim is not running — exercises require it")
                    .font(.system(size: 13))
                    .foregroundStyle(.quaternary)
            }
        }
    }
}
