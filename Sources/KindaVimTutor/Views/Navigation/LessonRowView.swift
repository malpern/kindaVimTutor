import SwiftUI

struct LessonRowView: View {
    let lesson: Lesson
    let chapterNumber: Int
    var isCompleted: Bool = false
    var progress: Double = 0

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(chapterNumber).\(lesson.number) \(lesson.title)")
                    .font(.body)
                Text(lesson.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.body)
            } else if progress > 0 {
                CircularProgressView(progress: progress)
                    .frame(width: 16, height: 16)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(.tertiary, lineWidth: 2)
            RingShape(progress: progress)
                .stroke(.green, style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
    }
}
