import SwiftUI

/// Root application state. Owns the curriculum, the selected lesson, and the
/// shared progress store. Lives for the lifetime of the window and is injected
/// into the sidebar and canvas views.
@Observable
@MainActor
public final class AppState {
    public var selectedLessonId: String?
    public let progressStore = ProgressStore()

    public let chapters: [Chapter] = Curriculum.chapters

    /// When set, `StepCanvasView` jumps to this step index on first appear.
    /// Cleared after use. Populated from `--initial-state` / env var.
    public internal(set) var initialStepIndex: Int?

    private var allLessons: [Lesson] {
        chapters.flatMap(\.lessons)
    }

    public var selectedLesson: Lesson? {
        guard let id = selectedLessonId else { return nil }
        return allLessons.first { $0.id == id }
    }

    public var selectedChapter: Chapter? {
        guard let lesson = selectedLesson else { return nil }
        return chapters.first { $0.lessons.contains(lesson) }
    }

    var nextLesson: Lesson? {
        guard let current = selectedLesson,
              let index = allLessons.firstIndex(of: current),
              index + 1 < allLessons.count else { return nil }
        return allLessons[index + 1]
    }

    public init() {
        if let spec = Self.initialStateSpec() {
            applyInitialState(spec)
        }
    }

    public func goToNextLesson() {
        if let next = nextLesson {
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedLessonId = next.id
            }
        }
    }

    public func goToFirstLesson() {
        if let first = allLessons.first {
            selectedLessonId = first.id
        }
    }

    // MARK: - Screenshot harness

    /// Reads an initial-state spec from `--initial-state VALUE` launch arg,
    /// falling back to the `KINDAVIM_INITIAL_STATE` env var. Used by the
    /// screenshot capture script to bring the app up in a known state.
    private static func initialStateSpec() -> String? {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "--initial-state"), i + 1 < args.count {
            return args[i + 1]
        }
        return ProcessInfo.processInfo.environment["KINDAVIM_INITIAL_STATE"]
    }

    /// Parses specs like `welcome`, `lesson:ch1.l1`, `lesson:ch1.l1:3`.
    private func applyInitialState(_ spec: String) {
        if spec == "welcome" { return }
        if spec.hasPrefix("lesson:") {
            let rest = spec.dropFirst("lesson:".count)
            let parts = rest.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            let lessonId = String(parts[0])
            selectedLessonId = lessonId
            if parts.count > 1, let n = Int(parts[1]) {
                initialStepIndex = n
            }
        }
    }
}
