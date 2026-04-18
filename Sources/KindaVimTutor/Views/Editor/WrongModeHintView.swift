import SwiftUI

struct WrongModeHintView: View {
    let isVisible: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 14))
            VStack(alignment: .leading, spacing: 1) {
                Text("You're in Insert mode")
                    .font(.system(size: 13, weight: .semibold))
                Text("Press Esc to enter Normal mode, then try the motion again")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            KeyCapView(label: "Esc", size: .small)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.orange.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.4), lineWidth: 1)
        )
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
