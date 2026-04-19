import SwiftUI

struct StatsView: View {
    let progressStore: ProgressStore

    var body: some View {
        VStack(spacing: 24) {
            Text("Your Progress")
                .font(.title2)
                .fontWeight(.bold)

            AchievementRingsView(
                lessonsProgress: lessonsProgress,
                exercisesProgress: exercisesProgress,
                streakProgress: streakWeekProgress
            )
            .animation(.spring(duration: 0.8), value: lessonsProgress)
            .animation(.spring(duration: 0.8), value: exercisesProgress)
            .animation(.spring(duration: 0.8), value: streakWeekProgress)

            AchievementRingsLegend(
                lessonsCompleted: progressStore.completedLessonCount,
                totalLessons: progressStore.totalLessons,
                exercisesCompleted: progressStore.completedExerciseCount,
                totalExercises: progressStore.totalExercises
            )
            .frame(width: 180)

            Divider()

            VStack(spacing: 8) {
                statRow(label: "Current streak",
                        value: streakValueText)
                statRow(label: "Practice days this week",
                        value: "\(progressStore.daysThisWeek) / 7")
                statRow(label: "Total practice time",
                        value: formatTime(progressStore.progress.totalTimeSpent))
                statRow(label: "Exercises completed",
                        value: "\(progressStore.completedExerciseCount)")
                statRow(label: "Lessons completed",
                        value: "\(progressStore.completedLessonCount)")
            }
        }
        .padding(24)
        .frame(width: 280)
    }

    private var lessonsProgress: Double {
        guard progressStore.totalLessons > 0 else { return 0 }
        return Double(progressStore.completedLessonCount) / Double(progressStore.totalLessons)
    }

    private var exercisesProgress: Double {
        guard progressStore.totalExercises > 0 else { return 0 }
        return Double(progressStore.completedExerciseCount) / Double(progressStore.totalExercises)
    }

    private var streakWeekProgress: Double {
        Double(progressStore.daysThisWeek) / 7.0
    }

    private var streakValueText: String {
        let s = progressStore.currentStreak
        if s == 0 { return "—" }
        if s == 1 { return "1 day" }
        return "\(s) days"
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.callout)
                .fontWeight(.medium)
                .monospacedDigit()
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}
