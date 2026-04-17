import Foundation

/// Disk-backed user progress. Persists `UserProgress` as JSON at
/// `~/Library/Application Support/kindaVimTutor/progress.json`. Only the best
/// result per exercise is retained (fewest keystrokes, then fastest time).
/// Also exposes aggregate progress (per-lesson / per-chapter) for the sidebar.
@Observable
@MainActor
public final class ProgressStore {
    public private(set) var progress: UserProgress

    private let fileURL: URL

    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("kindaVimTutor", isDirectory: true)
        self.fileURL = appDir.appendingPathComponent("progress.json")

        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode(UserProgress.self, from: data) {
            self.progress = saved
        } else {
            self.progress = UserProgress()
        }
    }

    public func recordCompletion(_ result: ExerciseResult) {
        // Keep the best result: fewest keystrokes, then fastest time.
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

    public func isExerciseCompleted(_ exerciseId: String) -> Bool {
        progress.completedExercises[exerciseId] != nil
    }

    public func bestResult(for exerciseId: String) -> ExerciseResult? {
        progress.completedExercises[exerciseId]
    }

    public func isLessonCompleted(_ lesson: Lesson) -> Bool {
        lesson.exercises.allSatisfy { isExerciseCompleted($0.id) }
    }

    private func save() {
        do {
            let dir = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(progress)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Intentionally swallow — progress is best-effort in the essentials build.
        }
    }
}
