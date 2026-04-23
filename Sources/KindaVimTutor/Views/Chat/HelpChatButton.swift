import SwiftUI

/// `?` chip in the top-right header. Toggles the chat panel on/off.
/// Disabled with a tooltip when Apple Intelligence isn't available so
/// pre-macOS-26 users understand why it doesn't respond.
struct HelpChatButton: View {
    @Binding var isChatActive: Bool
    let availability: ChatEngine.Availability

    @State private var isHovering = false

    var body: some View {
        Button(action: { if isEnabled { isChatActive.toggle() } }) {
            Image(systemName: "questionmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isEnabled ? Color.primary.opacity(0.88) : .secondary.opacity(0.5))
                .frame(width: 28, height: 24)
                .background {
                    if #available(macOS 26, *) {
                        Color.clear.glassEffect(
                            isChatActive ? .regular.tint(.accentColor.opacity(0.25)).interactive() : .regular.interactive(),
                            in: .rect(cornerRadius: 7)
                        )
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(.ultraThinMaterial)
                            if isChatActive {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(Color.accentColor.opacity(0.25))
                            }
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                        }
                    }
                }
        }
        .buttonStyle(.plain)
        .focusable(false)
        .disabled(!isEnabled)
        .opacity(isHovering || isChatActive ? 1 : 0.9)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .onHover { isHovering = $0 }
        .help(tooltip)
        .accessibilityLabel(isChatActive ? "Close Vim chat" : "Ask a Vim question")
    }

    private var isEnabled: Bool { availability != .notSupported }

    private var tooltip: String {
        switch availability {
        case .notSupported: return "Ask a Vim question — requires macOS 26 + Apple Intelligence"
        case .notEnabled:   return "Ask a Vim question (Apple Intelligence is off — click to see setup)"
        case .ready:        return isChatActive ? "Close Vim chat" : "Ask a Vim question"
        }
    }
}
