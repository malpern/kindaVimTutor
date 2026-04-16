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

            if !lesson.motionsIntroduced.isEmpty {
                Text(lesson.motionsIntroduced.joined(separator: "   "))
                    .font(.system(size: 17, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
