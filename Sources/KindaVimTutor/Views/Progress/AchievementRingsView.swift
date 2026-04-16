import SwiftUI

struct AchievementRingsView: View {
    let lessonsProgress: Double   // 0.0 - 1.0
    let exercisesProgress: Double
    let streakProgress: Double

    var compact: Bool = false

    private var ringWidth: CGFloat { compact ? 4 : 8 }

    var body: some View {
        ZStack {
            // Background rings
            ring(radius: outerRadius, color: .green.opacity(0.15))
            ring(radius: middleRadius, color: .blue.opacity(0.15))
            ring(radius: innerRadius, color: .orange.opacity(0.15))

            // Progress rings
            progressRing(radius: outerRadius, progress: lessonsProgress, color: .green)
            progressRing(radius: middleRadius, progress: exercisesProgress, color: .blue)
            progressRing(radius: innerRadius, progress: streakProgress, color: .orange)
        }
        .frame(width: totalSize, height: totalSize)
    }

    private var totalSize: CGFloat { compact ? 36 : 100 }
    private var outerRadius: CGFloat { (totalSize - ringWidth) / 2 }
    private var middleRadius: CGFloat { outerRadius - ringWidth - (compact ? 2 : 4) }
    private var innerRadius: CGFloat { middleRadius - ringWidth - (compact ? 2 : 4) }

    private func ring(radius: CGFloat, color: Color) -> some View {
        Circle()
            .stroke(color, lineWidth: ringWidth)
            .frame(width: radius * 2, height: radius * 2)
    }

    private func progressRing(radius: CGFloat, progress: Double, color: Color) -> some View {
        RingShape(progress: progress)
            .stroke(color, style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
            .frame(width: radius * 2, height: radius * 2)
    }
}

struct AchievementRingsLegend: View {
    let lessonsCompleted: Int
    let totalLessons: Int
    let exercisesCompleted: Int
    let totalExercises: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            legendRow(color: .green, label: "Lessons", value: "\(lessonsCompleted)/\(totalLessons)")
            legendRow(color: .blue, label: "Exercises", value: "\(exercisesCompleted)/\(totalExercises)")
            legendRow(color: .orange, label: "Streak", value: "—")
        }
    }

    private func legendRow(color: Color, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .monospacedDigit()
        }
    }
}
