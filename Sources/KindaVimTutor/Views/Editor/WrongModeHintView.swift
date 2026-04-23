import SwiftUI

struct WrongModeHintView: View {
    let isVisible: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 14))
            VStack(alignment: .leading, spacing: 3) {
                AnnotatedText(
                    string: "You're in {{insert}} mode",
                    font: .system(size: 13, weight: .semibold),
                    capSize: .small
                )
                AnnotatedText(
                    string: "Press `Esc` to enter {{normal}} mode, then try the motion again",
                    font: .system(size: 12),
                    capSize: .small,
                    foregroundStyle: Color.secondary
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            // Solid opaque background — translucent orange on top of
            // translucent orange on top of prose behind it was
            // unreadable. Keep the orange tint via the border and
            // icon alone.
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 10, y: 3)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -6)
        .animation(.easeInOut(duration: 0.18), value: isVisible)
        .allowsHitTesting(false)
    }
}

/// Characters that are meaningful Vim motions/operators in Normal mode.
/// If the user inserts one of these while in Insert mode, they probably
/// meant to be in Normal mode.
enum WrongModeDetector {
    static let motionKeys: Set<Character> = [
        "h", "j", "k", "l",
        "w", "b", "e",
        "x", "0", "$", "^",
        "d", "c", "y", "p",
        "A", "I", "D", "C", "Y",
        "g", "G", "H", "M", "L"
    ]

    /// Returns true if `new` differs from `old` by a single inserted character
    /// that matches a motion key.
    static func didUserTypeMotion(old: String, new: String) -> Bool {
        guard new.count == old.count + 1 else { return false }
        let oldChars = Array(old)
        let newChars = Array(new)
        for i in 0..<newChars.count {
            if i >= oldChars.count || oldChars[i] != newChars[i] {
                return motionKeys.contains(newChars[i])
            }
        }
        return false
    }
}
