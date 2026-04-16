import SwiftUI

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "keyboard")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("kindaVim Tutor")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Select a lesson from the sidebar to begin")
                .font(.title3)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                featureCard(
                    icon: "hand.raised",
                    title: "Learn",
                    description: "Bite-sized lessons that get to the point"
                )
                featureCard(
                    icon: "pencil.and.outline",
                    title: "Practice",
                    description: "Hands-on exercises in a real text editor"
                )
                featureCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Master",
                    description: "Track your progress and build muscle memory"
                )
            }
            .padding(.top, 20)
        }
        .padding(48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func featureCard(icon: String, title: String, description: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(.tint)
            Text(title)
                .font(.headline)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 160)
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .primary.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}
