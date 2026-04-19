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
            AppLogger.shared.info("lesson", "advance", fields: ["to": next.id])
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedLessonId = next.id
            }
        }
    }

    func goToFirstLesson() {
        if let first = allLessons.first {
            AppLogger.shared.info("lesson", "start", fields: ["id": first.id])
            selectedLessonId = first.id
        }
    }

    func goToLesson(_ id: String) {
        guard allLessons.contains(where: { $0.id == id }) else { return }
        AppLogger.shared.info("lesson", "jump", fields: ["to": id])
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedLessonId = id
        }
    }
}
