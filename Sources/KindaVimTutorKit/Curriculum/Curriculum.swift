import Foundation

/// Static namespace holding the full kindaVim curriculum. Each chapter is
/// defined in its own file as a `Curriculum` extension (see `Chapter1_*.swift`).
/// The app reads `Curriculum.chapters` at launch; there is no dynamic content.
enum Curriculum {
    static let chapters: [Chapter] = [
        chapter1,
    ]
}
