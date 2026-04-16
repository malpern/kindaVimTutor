import SwiftUI

struct LessonHeaderView: View {
    let lesson: Lesson
    let chapterTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(chapterTitle.uppercased())
                .font(.caption)
                .foregroundStyle(.secondary)
                .tracking(1)

            Text(lesson.title)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(lesson.subtitle)
                .font(.title3)
                .foregroundStyle(.secondary)

            if !lesson.motionsIntroduced.isEmpty {
                HStack(spacing: 6) {
                    Text("Motions:")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    ForEach(lesson.motionsIntroduced, id: \.self) { motion in
                        KeyCapView(label: motion)
                    }
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
    }
}
