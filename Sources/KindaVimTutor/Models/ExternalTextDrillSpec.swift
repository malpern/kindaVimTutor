import Foundation

/// Description of an "in the wild" text-editing drill — one that
/// runs in a system app (Notes, Mail, …) instead of the tutor's
/// built-in editor. Mirrors the role `FinderDrillSpec` plays for
/// the Finder-navigation drill: the author writes this, the
/// engine executes it.
struct ExternalTextDrillSpec: Hashable, Sendable {
    enum App: Sendable, Hashable {
        case notes
        case mail
    }

    struct Rep: Hashable, Sendable {
        /// Short human-readable direction shown in the coaching
        /// panel ("Delete the first line with `dd`").
        let instruction: String
        /// How the engine recognises completion against observed
        /// editor state.
        let predicate: CompletionPredicate
    }

    let title: String
    let subtitle: String
    /// Which system app the drill is authored for. The engine may
    /// fall back to the other if the user has a preference override
    /// or the preferred app isn't usable (e.g. Mail has no accounts).
    let preferredApp: App
    /// Text pre-populated into the fresh note / draft before the
    /// student begins. Use `\n` for line breaks.
    let seedBody: String
    let reps: [Rep]
}

/// Predicates evaluated against live editor state after each AX
/// notification to decide whether a rep has been completed.
///
/// Intentionally narrow to start: we'll add variants as specific
/// lessons need them, rather than speculating up front.
enum CompletionPredicate: Hashable, Sendable {
    /// The editor's current text equals this string.
    case textEquals(String)
    /// The editor's current text does NOT contain this substring.
    /// Useful for deletion drills ("delete 'foo' from the note").
    case textDoesNotContain(String)
    /// The editor's current text contains this substring, but the
    /// seed body did not. Useful for insert / change drills.
    case textContains(String)
}
