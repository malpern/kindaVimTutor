import AppKit
import Observation

/// Session-scoped set of keys the user is physically holding down,
/// normalized to the same label format used on KeyCapView (e.g.
/// "h", "Esc", "Space", ">", "[").
///
/// Any KeyCapView can check `isPressed(label:)` to give live
/// feedback when the student taps or holds the key it represents.
/// Fed from a single NSEvent local monitor installed high in the
/// view hierarchy (StepCanvasView) so we don't spawn per-cap
/// monitors.
@Observable
@MainActor
final class KeyPressTracker {
    static let shared = KeyPressTracker()

    private(set) var pressedKeys: Set<String> = []

    func isPressed(_ label: String) -> Bool {
        pressedKeys.contains(label)
    }

    func handleKeyDown(_ event: NSEvent) {
        guard let label = label(for: event) else { return }
        pressedKeys.insert(label)
    }

    func handleKeyUp(_ event: NSEvent) {
        guard let label = label(for: event) else { return }
        pressedKeys.remove(label)
    }

    func clearAll() {
        pressedKeys.removeAll()
    }

    /// Map an NSEvent to the label format KeyCapView uses. Named keys
    /// (Esc, Space, Tab, Return) are mapped from keyCode so they match
    /// the strings we render on the cap. Everything else falls back
    /// to `charactersIgnoringModifiers` which handles regular letters
    /// and symbols.
    private func label(for event: NSEvent) -> String? {
        switch event.keyCode {
        case 53:  return "Esc"
        case 49:  return "Space"
        case 48:  return "Tab"
        case 36:  return "Return"
        case 51:  return "Delete"
        case 123: return "Left"
        case 124: return "Right"
        case 125: return "Down"
        case 126: return "Up"
        default:
            guard let raw = event.charactersIgnoringModifiers?.first else { return nil }
            return String(raw)
        }
    }
}
