import SwiftUI

/// A single row inside the sidebar list. Shows the lesson title and a
/// completion checkmark when every exercise in the lesson has been finished.
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

#Preview("Lesson rows") {
    VStack(alignment: .leading) {
        LessonRowView(lesson: PreviewSamples.lesson, chapterNumber: 1, isCompleted: false)
        LessonRowView(lesson: PreviewSamples.lesson, chapterNumber: 1, isCompleted: true)
    }
    .frame(width: 220)
    .padding()
}
