import SwiftUI

struct LessonRowView: View {
    let lesson: Lesson
    let chapterNumber: Int
    var isCompleted: Bool = false
    var progress: Double = 0

    var body: some View {
        HStack(spacing: 6) {
            Text(lesson.title)
                .font(.system(size: 13, weight: .regular))
                .lineLimit(1)
                .foregroundStyle(isCompleted ? .secondary : .primary)
            Spacer()
            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}
