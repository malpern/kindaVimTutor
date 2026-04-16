import Foundation

struct Exercise: Identifiable, Sendable {
    let id: String
    let instruction: String
    let initialText: String
    let initialCursorPosition: Int
    let expectedText: String
    let expectedCursorPosition: Int?
    let hints: [String]

    enum Difficulty: String, Sendable, Codable {
        case learn
        case practice
        case master
    }

    let difficulty: Difficulty
}
