import SwiftUI

struct LessonView: View {
    let lesson: Lesson
    let chapterTitle: String
    let progressStore: ProgressStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                LessonHeaderView(lesson: lesson, chapterTitle: chapterTitle)

                Divider()

                ExplanationView(blocks: lesson.explanation)

                if !lesson.exercises.isEmpty {
                    Divider()
                        .padding(.vertical, 4)

                    Text("Exercises")
                        .font(.title2)
                        .fontWeight(.bold)

                    ForEach(Array(lesson.exercises.enumerated()), id: \.element.id) { index, exercise in
                        ExerciseContainerView(exercise: exercise, exerciseNumber: index + 1, progressStore: progressStore)
                    }
                }
            }
            .padding(32)
            .frame(maxWidth: 720, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .background(.background)
    }
}
