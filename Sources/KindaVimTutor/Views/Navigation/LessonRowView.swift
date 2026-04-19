import SwiftUI

struct LessonRowView: View {
    let lesson: Lesson
    let chapterNumber: Int
    var isCompleted: Bool = false
    var progress: Double = 0

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            // Left rail: subtly brightens on hover, tints green when completed.
            Rectangle()
                .fill(railColor)
                .frame(width: 2)
                .padding(.leading, 4)
                .animation(.easeInOut(duration: 0.15), value: isHovering)
                .animation(.easeInOut(duration: 0.2), value: isCompleted)

            Text(lesson.title)
                .font(.system(size: 13, weight: .regular))
                .lineLimit(1)
                .foregroundStyle(titleColor)
                .animation(.easeInOut(duration: 0.15), value: isHovering)

            Spacer(minLength: 4)

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.green.opacity(0.8))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private var railColor: Color {
        if isCompleted {
            return .green.opacity(0.55)
        }
        return .secondary.opacity(isHovering ? 0.38 : 0.15)
    }

    private var titleColor: Color {
        if isCompleted {
            return .secondary
        }
        return isHovering ? .primary : .primary.opacity(0.92)
    }
}
