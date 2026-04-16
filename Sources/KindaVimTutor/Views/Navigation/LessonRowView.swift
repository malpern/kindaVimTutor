import SwiftUI

struct LessonRowView: View {
    let lesson: Lesson
    let chapterNumber: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(chapterNumber).\(lesson.number) \(lesson.title)")
                .font(.body)
            Text(lesson.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
