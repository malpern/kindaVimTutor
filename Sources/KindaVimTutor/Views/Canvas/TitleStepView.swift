import SwiftUI

struct TitleStepView: View {
    let lesson: Lesson
    let chapterTitle: String

    @State private var animateIn = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Text(chapterTitle.uppercased())
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tint)
                .tracking(2)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 8)

            Text(lesson.title)
                .font(.system(size: 44, weight: .bold))
                .tracking(-1.2)
                .multilineTextAlignment(.center)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 12)

            Text(lesson.subtitle)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(.secondary)
                .tracking(-0.3)
                .multilineTextAlignment(.center)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 12)

            if !lesson.motionsIntroduced.isEmpty {
                HStack(spacing: 12) {
                    ForEach(lesson.motionsIntroduced, id: \.self) { motion in
                        Text(motion)
                            .font(.system(size: 22, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 12)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 12)
            }

            Spacer()

            Text("Press → to continue")
                .font(.system(size: 13))
                .foregroundStyle(.quaternary)
                .padding(.bottom, 40)
                .opacity(animateIn ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.05)) {
                animateIn = true
            }
        }
        .onDisappear {
            animateIn = false
        }
    }
}
