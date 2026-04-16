import SwiftUI

struct WelcomeView: View {
    var onStartLearning: (() -> Void)?

    @State private var animateIn = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                // Hero
                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        KeyCapView(label: "h", size: .large)
                        KeyCapView(label: "j", size: .large)
                        KeyCapView(label: "k", size: .large)
                        KeyCapView(label: "l", size: .large)
                    }
                    .scaleEffect(animateIn ? 1 : 0.8)
                    .opacity(animateIn ? 1 : 0)

                    Text("kindaVim Tutor")
                        .font(.system(size: 36, weight: .bold, design: .default))
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 10)

                    Text("Learn Vim motions for macOS,\none exercise at a time.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 10)
                }

                // CTA
                if let onStartLearning {
                    Button(action: onStartLearning) {
                        HStack(spacing: 8) {
                            Text("Start Learning")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .frame(minWidth: 160)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 10)
                }

                // Feature cards
                HStack(spacing: 20) {
                    featureCard(
                        icon: "text.cursor",
                        title: "Learn",
                        description: "Bite-sized lessons that build on each other"
                    )
                    featureCard(
                        icon: "pencil.and.outline",
                        title: "Practice",
                        description: "Hands-on exercises with real text editing"
                    )
                    featureCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Master",
                        description: "Track your progress with achievement rings"
                    )
                }
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 15)
            }

            Spacer()

            // kindaVim status
            kindaVimStatus
                .padding(.bottom, 24)
                .opacity(animateIn ? 1 : 0)
        }
        .padding(48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                animateIn = true
            }
        }
    }

    private func featureCard(icon: String, title: String, description: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(height: 28)
            Text(title)
                .font(.headline)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .frame(width: 180)
        .padding(20)
        .background(.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var kindaVimStatus: some View {
        HStack(spacing: 6) {
            let isRunning = !NSRunningApplication.runningApplications(
                withBundleIdentifier: "mo.com.sleeplessmind.kindaVim"
            ).isEmpty

            if isRunning {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("kindaVim is running")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("kindaVim is not running — exercises require it")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
