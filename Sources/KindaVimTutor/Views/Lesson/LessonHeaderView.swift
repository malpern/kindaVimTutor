import SwiftUI

struct LessonHeaderView: View {
    let lesson: Lesson
    let chapterTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(chapterTitle.uppercased())
                .font(Typography.chapterLabel)
                .foregroundStyle(.tint)
                .tracking(Typography.chapterTracking)

            Text(lesson.title)
                .font(Typography.lessonTitle)
                .tracking(Typography.headingTracking)

            Text(lesson.subtitle)
                .font(Typography.lessonSubtitle)
                .foregroundStyle(.secondary)
                .tracking(Typography.titleTracking)

            if !lesson.motionsIntroduced.isEmpty {
                HStack(spacing: 8) {
                    ForEach(lesson.motionsIntroduced, id: \.self) { motion in
                        KeyCapView(label: motion, size: .large)
                    }
                }
                .padding(.top, 10)
            }

            Divider()
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }
}
