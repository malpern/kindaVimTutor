import SwiftUI

/// The first slide of every lesson: chapter label, lesson title, subtitle,
/// and a "press L to begin" hint. Static text with a simple fade-in.
struct TitleStepView: View {
    let lesson: Lesson
    let chapterTitle: String

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Text(chapterTitle.uppercased())
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tint)
                .tracking(2)

            Text(lesson.title)
                .font(.system(size: 44, weight: .bold))
                .tracking(-1.2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 600)

            Text(lesson.subtitle)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(.secondary)
                .tracking(-0.3)
                .multilineTextAlignment(.center)

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
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.35), value: appeared)
        .onAppear { appeared = true }
        .onDisappear { appeared = false }
    }
}

#Preview("Title slide") {
    TitleStepView(lesson: PreviewSamples.lesson, chapterTitle: "Survival Kit")
        .frame(width: 900, height: 600)
}
