import SwiftUI

struct SidebarView: View {
    let chapters: [Chapter]
    @Binding var selectedLessonId: String?
    let progressStore: ProgressStore

    var body: some View {
        List(selection: $selectedLessonId) {
            // Progress summary at top
            sidebarHeader

            ForEach(chapters) { chapter in
                Section {
                    ForEach(chapter.lessons) { lesson in
                        LessonRowView(
                            lesson: lesson,
                            chapterNumber: chapter.number,
                            isCompleted: progressStore.isLessonCompleted(lesson),
                            progress: progressStore.lessonProgress(lesson)
                        )
                        .tag(lesson.id)
                    }
                } header: {
                    ChapterRowView(chapter: chapter)
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 230)
        .navigationTitle("kindaVim Tutor")
    }

    private var sidebarHeader: some View {
        VStack(spacing: 8) {
            HStack {
                AchievementRingsView(
                    lessonsProgress: Double(progressStore.completedLessonCount) / max(Double(progressStore.totalLessons), 1),
                    exercisesProgress: Double(progressStore.completedExerciseCount) / max(Double(progressStore.totalExercises), 1),
                    streakProgress: 0,
                    compact: true
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(progressStore.completedExerciseCount)/\(progressStore.totalExercises) exercises")
                        .font(.caption)
                        .monospacedDigit()
                    Text("\(progressStore.completedLessonCount)/\(progressStore.totalLessons) lessons")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            .padding(.vertical, 4)
        }
    }
}
