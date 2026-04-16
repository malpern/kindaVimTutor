import SwiftUI

struct LessonView: View {
    let lesson: Lesson
    let chapterTitle: String
    let progressStore: ProgressStore

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 28) {
                LessonHeaderView(lesson: lesson, chapterTitle: chapterTitle)

                ExplanationView(blocks: lesson.explanation)

                if !lesson.exercises.isEmpty {
                    exercisesSection
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 40)
            .padding(.top, 32)
            .padding(.bottom, 24)
            .frame(maxWidth: 700, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .scrollContentBackground(.hidden)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 8) {
                Text("Exercises")
                    .font(Typography.sectionHeading)
                Spacer()
                if progressStore.isLessonCompleted(lesson) {
                    Label("All complete", systemImage: "checkmark.circle.fill")
                        .font(.callout)
                        .foregroundStyle(.green)
                }
            }
            .padding(.top, 8)

            ForEach(Array(lesson.exercises.enumerated()), id: \.element.id) { index, exercise in
                ExerciseContainerView(exercise: exercise, exerciseNumber: index + 1, progressStore: progressStore)
            }
        }
    }
}
