import SwiftUI

/// Displayed when no lesson is selected. Prompts the user to press `L` (or
/// `space`) to start the first lesson — mirroring the in-lesson navigation keys.
public struct WelcomeView: View {
    var onStartLearning: (() -> Void)?

    @State private var appeared = false

    public init(onStartLearning: (() -> Void)? = nil) {
        self.onStartLearning = onStartLearning
    }

    public var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                Text("kindaVim Tutor")
                    .font(.system(size: 44, weight: .bold))
                    .tracking(-1.2)

                Text("Learn Vim motions for macOS,\none exercise at a time.")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.secondary)
                    .tracking(-0.3)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            HStack(spacing: 10) {
                KeyCapView(label: "L", size: .regular)
                    .scaleEffect(0.92)
                Text("press to begin")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary.opacity(0.82))
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .focusable()
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4), value: appeared)
        .onAppear { appeared = true }
        .onKeyPress { keyPress in
            if keyPress.characters.first == "l" || keyPress.characters.first == " " {
                onStartLearning?()
                return .handled
            }
            return .ignored
        }
    }
}

#Preview("Welcome") {
    WelcomeView(onStartLearning: {})
        .frame(width: 900, height: 600)
}
