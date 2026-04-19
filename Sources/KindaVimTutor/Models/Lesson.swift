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
    /// Optional interactive step inserted between explanation and drills.
    /// Used for exercises that aren't text-mutation based (e.g. the
    /// Normal/Insert mode-ping-pong in Ch1).
    let interactive: InteractiveStep?

    init(id: String, number: Int, title: String, subtitle: String,
         explanation: [ContentBlock], exercises: [Exercise],
         motionsIntroduced: [String], interactive: InteractiveStep? = nil) {
        self.id = id
        self.number = number
        self.title = title
        self.subtitle = subtitle
        self.explanation = explanation
        self.exercises = exercises
        self.motionsIntroduced = motionsIntroduced
        self.interactive = interactive
    }
}

enum InteractiveStep: Hashable, Sendable {
    /// Student must cycle kindaVim through the given mode sequence by
    /// pressing Esc / i / v in any kindaVim-controlled text field. The
    /// exercise watches ModeMonitor; no text editing involved.
    ///
    /// `visualPreviewLessonId` optionally enables a muted "Visual" chip
    /// next to the required targets that jumps to the given lesson when
    /// clicked — used to foreshadow Ch5 from the Ch1 modes lesson.
    case modeSequence(expected: [VimMode],
                      instruction: String,
                      visualPreviewLessonId: String?)
}
