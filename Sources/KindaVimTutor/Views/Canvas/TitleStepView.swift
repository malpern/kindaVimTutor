import SwiftUI

struct TitleStepView: View {
    let lesson: Lesson
    let chapterTitle: String

    @State private var showChapter = false
    @State private var showSubtitle = false
    @State private var showHint = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            // Chapter label — fades in first, no movement
            Text(chapterTitle.uppercased())
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tint)
                .tracking(2)
                .opacity(showChapter ? 1 : 0)
                .offset(y: showChapter ? 0 : 4)

            // Title — types in
            TypewriterText(
                lesson.title,
                font: .system(size: 44, weight: .bold),
                foregroundStyle: .primary,
                alignment: .center
            ) {
                withAnimation(.spring(duration: 0.5, bounce: 0.0)) {
                    showSubtitle = true
                }
            }
            .tracking(-1.2)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 600)

            // Subtitle — types in after title
            if showSubtitle {
                TypewriterText(
                    lesson.subtitle,
                    font: .system(size: 20, weight: .regular),
                    foregroundStyle: .secondary,
                    alignment: .center
                ) {
                    withAnimation(.easeOut(duration: 0.4).delay(0.15)) {
                        showHint = true
                    }
                }
                .tracking(-0.3)
                .multilineTextAlignment(.center)
                .transition(.opacity)
            }

            Spacer()

            // Navigation hint
            if showHint {
                HStack(spacing: 10) {
                    KeyCapView(label: "]", size: .regular)
                        .scaleEffect(0.92)
                        .shadow(color: .white.opacity(0.06), radius: 10, y: 1)
                    Text("press to begin")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.secondary.opacity(0.82))
                }
                .opacity(0.92)
                .padding(.bottom, 40)
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.0).delay(0.05)) {
                showChapter = true
            }
        }
        .onDisappear {
            showChapter = false
            showSubtitle = false
            showHint = false
        }
    }
}
