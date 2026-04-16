import SwiftUI

struct LessonView: View {
    let lesson: Lesson
    let chapterTitle: String
    let progressStore: ProgressStore
    var nextLesson: Lesson?
    var onNextLesson: (() -> Void)?

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 28) {
                LessonHeaderView(lesson: lesson, chapterTitle: chapterTitle)

                ExplanationView(blocks: lesson.explanation)

                if !lesson.exercises.isEmpty {
                    exercisesSection
                }

                lessonFooter
                    .padding(.top, 12)

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
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.top, 8)
            .animation(.spring(duration: 0.4), value: progressStore.isLessonCompleted(lesson))

            ForEach(Array(lesson.exercises.enumerated()), id: \.element.id) { index, exercise in
                ExerciseContainerView(exercise: exercise, exerciseNumber: index + 1, progressStore: progressStore)
            }
        }
    }

    @ViewBuilder
    private var lessonFooter: some View {
        if progressStore.isLessonCompleted(lesson), let nextLesson, let onNextLesson {
            VStack(spacing: 16) {
                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Lesson complete!")
                            .font(.headline)
                            .foregroundStyle(.green)
                        Text("Up next: \(nextLesson.title)")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(action: onNextLesson) {
                        HStack(spacing: 6) {
                            Text("Next Lesson")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(.vertical, 8)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else if !progressStore.isLessonCompleted(lesson) {
            // Show progress hint
            let completed = lesson.exercises.filter { progressStore.isExerciseCompleted($0.id) }.count
            let total = lesson.exercises.count
            if completed > 0 {
                HStack {
                    Spacer()
                    Text("\(completed) of \(total) exercises completed")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
    }
}
