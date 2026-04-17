import SwiftUI

/// A grouping of lessons under a single theme (e.g. "Survival Kit").
/// Defined statically in `Curriculum/Chapter*.swift` and surfaced through the sidebar.
public struct Chapter: Identifiable, Sendable {
    public let id: String
    public let number: Int
    public let title: String
    public let subtitle: String
    public let systemImage: String
    public let lessons: [Lesson]

    public init(id: String, number: Int, title: String, subtitle: String, systemImage: String, lessons: [Lesson]) {
        self.id = id
        self.number = number
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.lessons = lessons
    }
}
