import SwiftUI

@Observable
@MainActor
final class AppState {
    var selectedLessonId: String?
    let modeMonitor = ModeMonitor()
    let progressStore = ProgressStore()
    let inspectorState = ExerciseInspectorState()

    let chapters: [Chapter] = Curriculum.chapters

    private var allLessons: [Lesson] {
        chapters.flatMap(\.lessons)
    }

    var selectedLesson: Lesson? {
        guard let id = selectedLessonId else { return nil }
        return allLessons.first { $0.id == id }
    }

    var selectedChapter: Chapter? {
        guard let lesson = selectedLesson else { return nil }
        return chapters.first { $0.lessons.contains(lesson) }
    }

    var nextLesson: Lesson? {
        guard let current = selectedLesson,
              let index = allLessons.firstIndex(of: current),
              index + 1 < allLessons.count else { return nil }
        return allLessons[index + 1]
    }

    func goToNextLesson() {
        if let next = nextLesson {
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedLessonId = next.id
            }
        }
    }

    func goToFirstLesson() {
        if let first = allLessons.first {
            selectedLessonId = first.id
        }
    }
}
