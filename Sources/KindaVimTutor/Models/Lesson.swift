import Foundation

struct Lesson: Identifiable, Hashable, Sendable {
    static func == (lhs: Lesson, rhs: Lesson) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    let id: String
    let number: Int
    let title: String
    let subtitle: String
    let explanation: [ContentBlock]
    let exercises: [Exercise]
    let motionsIntroduced: [String]
}
