import SwiftUI

/// Shared "press to continue" / "press to begin" CTA. Accepts an optional
/// `action` — when set, the whole hint becomes clickable so users who'd
/// rather use the mouse don't have to hunt for the `]` key.
struct AdvanceHintView: View {
    let label: String
    var action: (() -> Void)? = nil

    @State private var isHovering = false

    init(_ label: String = "to continue", action: (() -> Void)? = nil) {
        self.label = label
        self.action = action
    }

    var body: some View {
        if let action {
            Button(action: action) { content }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isHovering = hovering
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: 10) {
            KeyCapView(label: "]", size: .regular)
                .scaleEffect(isHovering ? 0.96 : 0.92)
                .shadow(color: .white.opacity(isHovering ? 0.12 : 0.06), radius: 10, y: 1)
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.secondary.opacity(isHovering ? 1.0 : 0.82))
        }
        .opacity(isHovering ? 1.0 : 0.92)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .contentShape(Rectangle())
    }
}
