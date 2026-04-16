import SwiftUI

struct LessonView: View {
    let lesson: Lesson
    let chapterTitle: String
    let progressStore: ProgressStore
    let inspectorState: ExerciseInspectorState
    var nextLesson: Lesson?
    var onNextLesson: (() -> Void)?

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 0) {
                LessonHeaderView(lesson: lesson, chapterTitle: chapterTitle)

                Spacer().frame(height: 48)

                ExplanationView(blocks: lesson.explanation)

                if !lesson.exercises.isEmpty {
                    Spacer().frame(height: 56)

                    Text("Exercises")
                        .font(Typography.sectionHeading)
                        .tracking(Typography.titleTracking)

                    Spacer().frame(height: 28)

                    ForEach(Array(lesson.exercises.enumerated()), id: \.element.id) { index, exercise in
                        if index > 0 {
                            Divider()
                                .opacity(0.3)
                                .padding(.vertical, 32)
                        }
                        ExerciseContainerView(
                            exercise: exercise,
                            exerciseNumber: index + 1,
                            progressStore: progressStore,
                            inspectorState: inspectorState
                        )
                    }
                }

                lessonFooter
                    .padding(.top, 48)

                Spacer(minLength: 64)
            }
            .padding(.horizontal, 56)
            .padding(.top, 48)
            .frame(maxWidth: 700, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .scrollContentBackground(.hidden)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    @ViewBuilder
    private var lessonFooter: some View {
        if progressStore.isLessonCompleted(lesson), let nextLesson, let onNextLesson {
            VStack(spacing: 16) {
                Divider()
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("All exercises completed")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Text("Up next: \(nextLesson.title)")
                            .font(.callout)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    Button(action: onNextLesson) {
                        HStack(spacing: 6) {
                            Text("Next Lesson")
                                .fontWeight(.medium)
                            Image(systemName: "arrow.right")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
            }
        }
    }
}
