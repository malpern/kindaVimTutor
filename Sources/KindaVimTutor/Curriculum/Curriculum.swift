import Foundation

enum Curriculum {
    static let chapters: [Chapter] = [
        chapter0,
        chapter1,
        chapter2,
        chapter3,
        chapter4,
        chapter5,
        chapter6,
    ]

    static func lesson(containing exerciseId: String) -> Lesson? {
        chapters.flatMap(\.lessons).first { lesson in
            lesson.exercises.contains { $0.id == exerciseId }
        }
    }

    static func lesson(withId id: String) -> Lesson? {
        chapters.flatMap(\.lessons).first { $0.id == id }
    }
}
