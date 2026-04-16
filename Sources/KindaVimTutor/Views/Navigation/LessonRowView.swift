import SwiftUI

struct LessonRowView: View {
    let lesson: Lesson
    let chapterNumber: Int
    var isCompleted: Bool = false
    var progress: Double = 0

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text("\(chapterNumber).\(lesson.number)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                    Text(lesson.title)
                        .font(.system(size: 13, weight: .medium))
                        .tracking(-0.2)
                        .lineLimit(1)
                }

                // Motion keycap badges
                if !lesson.motionsIntroduced.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(lesson.motionsIntroduced.prefix(5), id: \.self) { motion in
                            KeyCapView(label: motion, size: .small)
                        }
                        if lesson.motionsIntroduced.count > 5 {
                            Text("+\(lesson.motionsIntroduced.count - 5)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Spacer()

            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            } else if progress > 0 {
                CircularProgressView(progress: progress)
                    .frame(width: 14, height: 14)
            }
        }
        .padding(.vertical, 3)
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
