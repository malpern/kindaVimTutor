import SwiftUI

struct WelcomeView: View {
    var onStartLearning: (() -> Void)?

    @State private var animateIn = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                Text("kindaVim Tutor")
                    .font(.system(size: 44, weight: .bold))
                    .tracking(-1.2)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 12)

                Text("Learn Vim motions for macOS,\none exercise at a time.")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.secondary)
                    .tracking(-0.3)
                    .multilineTextAlignment(.center)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 12)

            }

            Spacer()

            // Navigation hint + kindaVim status
            VStack(spacing: 16) {
                HStack(spacing: 10) {
                    KeyCapView(label: "L", size: .regular)
                        .scaleEffect(0.92)
                        .shadow(color: .white.opacity(0.06), radius: 10, y: 1)
                    Text("press to begin")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.secondary.opacity(0.82))
                }
                .opacity(0.92)

                kindaVimStatus
            }
            .padding(.bottom, 40)
            .opacity(animateIn ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .focusable()
        .accessibilityIdentifier("WelcomeScreen")
        .accessibilityLabel("welcome lesson=none")
        .onKeyPress { keyPress in
            if keyPress.characters.first == "l" || keyPress.characters.first == " " {
                onStartLearning?()
                return .handled
            }
            return .ignored
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.05)) {
                animateIn = true
            }
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
