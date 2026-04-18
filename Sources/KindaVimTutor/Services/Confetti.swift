import AppKit

/// Triggers Raycast's confetti extension via its URL scheme.
/// No-op (silently fails) if Raycast isn't installed.
/// Because opening a raycast:// URL briefly steals focus, we reactivate
/// our own app shortly after each fire.
enum Confetti {
    private static let url = URL(string: "raycast://extensions/raycast/raycast/confetti")!

    static func fire() {
        NSWorkspace.shared.open(url)
        reclaimFocus()
    }

    static func fireBurst(times: Int = 2, interval: TimeInterval = 0.35) {
        guard times > 0 else { return }
        for i in 0..<times {
            let delay = Double(i) * interval
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                NSWorkspace.shared.open(url)
            }
        }
        // Reclaim after the final fire lands.
        let total = Double(times - 1) * interval
        DispatchQueue.main.asyncAfter(deadline: .now() + total + 0.15) {
            reclaimFocus()
        }
    }

    private static func reclaimFocus() {
        // Raycast can take a beat to become active; delay slightly so our
        // activation isn't overridden.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            NSRunningApplication.current.activate()
        }
    }
}
