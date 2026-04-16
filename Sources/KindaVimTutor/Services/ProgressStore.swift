import Foundation

@Observable
@MainActor
final class ProgressStore {
    private(set) var progress: UserProgress

    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("kindaVimTutor", isDirectory: true)
        self.fileURL = appDir.appendingPathComponent("progress.json")

        // Load existing progress or start fresh
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode(UserProgress.self, from: data) {
            self.progress = saved
        } else {
            self.progress = UserProgress()
        }
    }

    func recordCompletion(_ result: ExerciseResult) {
        // Keep the best result (fewest keystrokes, then fastest time)
        if let existing = progress.completedExercises[result.exerciseId] {
            if result.keystrokeCount < existing.keystrokeCount
                || (result.keystrokeCount == existing.keystrokeCount && result.timeSeconds < existing.timeSeconds) {
                progress.completedExercises[result.exerciseId] = result
            }
        } else {
            progress.completedExercises[result.exerciseId] = result
        }

        progress.totalTimeSpent += result.timeSeconds
        progress.lastPracticeDate = Date()
        save()
    }

    func isExerciseCompleted(_ exerciseId: String) -> Bool {
        progress.completedExercises[exerciseId] != nil
    }

    func isLessonCompleted(_ lesson: Lesson) -> Bool {
        lesson.exercises.allSatisfy { isExerciseCompleted($0.id) }
    }

    func lessonProgress(_ lesson: Lesson) -> Double {
        guard !lesson.exercises.isEmpty else { return 1.0 }
        let completed = lesson.exercises.filter { isExerciseCompleted($0.id) }.count
        return Double(completed) / Double(lesson.exercises.count)
    }

    func chapterProgress(_ chapter: Chapter) -> Double {
        guard !chapter.lessons.isEmpty else { return 1.0 }
        let totalExercises = chapter.lessons.flatMap(\.exercises).count
        guard totalExercises > 0 else { return 1.0 }
        let completed = chapter.lessons.flatMap(\.exercises).filter { isExerciseCompleted($0.id) }.count
        return Double(completed) / Double(totalExercises)
    }

    var totalExercises: Int {
        Curriculum.chapters.flatMap(\.lessons).flatMap(\.exercises).count
    }

    var completedExerciseCount: Int {
        progress.completedExercises.count
    }

    var completedLessonCount: Int {
        Curriculum.chapters.flatMap(\.lessons).filter { isLessonCompleted($0) }.count
    }

    var totalLessons: Int {
        Curriculum.chapters.flatMap(\.lessons).count
    }

    private func save() {
        do {
            let dir = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(progress)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save progress: \(error)")
        }
    }
}
