import SwiftUI

@Observable
@MainActor
final class AppState {
    var selectedLessonId: String?
    let modeMonitor = ModeMonitor()

    let chapters: [Chapter] = Curriculum.chapters

    var selectedLesson: Lesson? {
        guard let id = selectedLessonId else { return nil }
        return chapters.flatMap(\.lessons).first { $0.id == id }
    }

    var selectedChapter: Chapter? {
        guard let lesson = selectedLesson else { return nil }
        return chapters.first { $0.lessons.contains(lesson) }
    }
}
