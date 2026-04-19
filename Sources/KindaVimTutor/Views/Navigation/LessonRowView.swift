import SwiftUI

struct LessonRowView: View {
    let lesson: Lesson
    let chapterNumber: Int
    var isCompleted: Bool = false
    var progress: Double = 0

    var body: some View {
        HStack(spacing: 8) {
            // Indent: a thin vertical rail reinforces "child of chapter".
            Rectangle()
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 2)
                .padding(.leading, 4)
            Text(lesson.title)
                .font(.system(size: 13, weight: .regular))
                .lineLimit(1)
                .foregroundStyle(isCompleted ? .secondary : .primary)
            Spacer(minLength: 4)
            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.green.opacity(0.75))
            }
        }
        .padding(.vertical, 3)
    }
}
