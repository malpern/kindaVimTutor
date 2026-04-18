import SwiftUI

/// Shared "press to continue" / "press to begin" CTA used at the bottom of
/// every title, content, and completed drill step. Matches the title-splash
/// style: regular `]` keycap + muted label.
struct AdvanceHintView: View {
    let label: String

    init(_ label: String = "press to continue") {
        self.label = label
    }

    var body: some View {
        HStack(spacing: 10) {
            KeyCapView(label: "]", size: .regular)
                .scaleEffect(0.92)
                .shadow(color: .white.opacity(0.06), radius: 10, y: 1)
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.secondary.opacity(0.82))
        }
        .opacity(0.92)
    }
}
