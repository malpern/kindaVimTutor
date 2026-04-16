import SwiftUI

struct Chapter: Identifiable, Sendable {
    let id: String
    let number: Int
    let title: String
    let subtitle: String
    let systemImage: String
    let lessons: [Lesson]
}
