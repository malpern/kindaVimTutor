import AppKit
import SwiftUI

private struct PointingHandCursorModifier: ViewModifier {
    @State private var cursorPushed = false

    func body(content: Content) -> some View {
        content.onHover { isHovering in
            if isHovering, !cursorPushed {
                NSCursor.pointingHand.push()
                cursorPushed = true
            } else if !isHovering, cursorPushed {
                NSCursor.pop()
                cursorPushed = false
            }
        }
    }
}

extension View {
    func pointingHandCursor() -> some View {
        modifier(PointingHandCursorModifier())
    }
}
