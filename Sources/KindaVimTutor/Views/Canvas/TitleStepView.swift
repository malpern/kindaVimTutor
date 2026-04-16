import SwiftUI

struct TitleStepView: View {
    let lesson: Lesson
    let chapterTitle: String

    @State private var showChapter = false
    @State private var titleDone = false
    @State private var showSubtitle = false
    @State private var showMotions = false
    @State private var showHint = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            // Chapter label — fades in first
            Text(chapterTitle.uppercased())
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tint)
                .tracking(2)
                .opacity(showChapter ? 1 : 0)

            // Title — types in
            TypewriterText(
                lesson.title,
                font: .system(size: 44, weight: .bold),
                foregroundStyle: .primary
            ) {
                titleDone = true
                withAnimation(.easeOut(duration: 0.4)) {
                    showSubtitle = true
                }
                withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                    showMotions = true
                }
                withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
                    showHint = true
                }
            }
            .tracking(-1.2)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 600)

            // Subtitle — fades in after title
            if showSubtitle {
                Text(lesson.subtitle)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.secondary)
                    .tracking(-0.3)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }

            // Motions — fade in after subtitle
            if showMotions, !lesson.motionsIntroduced.isEmpty {
                HStack(spacing: 12) {
                    ForEach(lesson.motionsIntroduced, id: \.self) { motion in
                        Text(motion)
                            .font(.system(size: 22, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 12)
                .transition(.opacity)
            }

            Spacer()

            // Navigation hint
            if showHint {
                Text("Press l to continue")
                    .font(.system(size: 13))
                    .foregroundStyle(.quaternary)
                    .padding(.bottom, 40)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                showChapter = true
            }
        }
        .onDisappear {
            showChapter = false
            titleDone = false
            showSubtitle = false
            showMotions = false
            showHint = false
        }
    }
}
