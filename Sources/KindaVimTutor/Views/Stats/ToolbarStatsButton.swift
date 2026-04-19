import SwiftUI

/// Clickable toolbar item that shows the achievement rings and opens
/// the stats popover. Owns its own hover state so it can give a
/// clear interactive treatment (scale + brighten + pointing cursor)
/// without those details living inside the App scene body.
struct ToolbarStatsButton: View {
    let progressStore: ProgressStore
    @Binding var showStats: Bool

    @State private var isHovering = false

    var body: some View {
        Button {
            showStats.toggle()
        } label: {
            AchievementRingsView(
                lessonsProgress: lessonProgress,
                exercisesProgress: exerciseProgress,
                streakProgress: 0,
                compact: true
            )
            .scaleEffect(isHovering ? 1.08 : 1.0)
            .shadow(
                color: .accentColor.opacity(isHovering ? 0.35 : 0),
                radius: isHovering ? 6 : 0
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.25, bounce: 0.15), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
            if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
        .popover(isPresented: $showStats) {
            StatsView(progressStore: progressStore)
        }
        .help(tooltip)
        .accessibilityLabel("Show progress")
    }

    private var lessonProgress: Double {
        Double(progressStore.completedLessonCount)
            / max(Double(progressStore.totalLessons), 1)
    }

    private var exerciseProgress: Double {
        Double(progressStore.completedExerciseCount)
            / max(Double(progressStore.totalExercises), 1)
    }

    private var tooltip: String {
        let lessonPct = Int((lessonProgress * 100).rounded())
        let exercisePct = Int((exerciseProgress * 100).rounded())
        return "Progress — \(lessonPct)% lessons, \(exercisePct)% exercises (⌘⇧P)"
    }
}
