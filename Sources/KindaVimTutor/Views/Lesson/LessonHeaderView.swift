import SwiftUI

struct LessonHeaderView: View {
    let lesson: Lesson
    let chapterTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(chapterTitle.uppercased())
                .font(Typography.chapterLabel)
                .foregroundStyle(.tint)
                .tracking(1.5)

            Text(lesson.title)
                .font(Typography.lessonTitle)

            Text(lesson.subtitle)
                .font(Typography.lessonSubtitle)
                .foregroundStyle(.secondary)

            if !lesson.motionsIntroduced.isEmpty {
                HStack(spacing: 8) {
                    ForEach(lesson.motionsIntroduced, id: \.self) { motion in
                        KeyCapView(label: motion, size: .large)
                    }
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 12)
    }
}
