import SwiftUI

struct ManualHelpButton: View {
    @Binding var isActive: Bool

    @State private var isHovering = false

    var body: some View {
        Button(action: { isActive.toggle() }) {
            Text("Manual")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.primary.opacity(0.9))
                .padding(.horizontal, 10)
                .frame(height: 24)
                .background {
                    if #available(macOS 26, *) {
                        Color.clear.glassEffect(
                            isActive ? .regular.tint(.accentColor.opacity(0.18)).interactive() : .regular.interactive(),
                            in: .rect(cornerRadius: 7)
                        )
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(.ultraThinMaterial)
                            if isActive {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(Color.accentColor.opacity(0.18))
                            }
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                        }
                    }
                }
        }
        .buttonStyle(.plain)
        .opacity(isHovering || isActive ? 1 : 0.92)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .onHover { isHovering = $0 }
        .help(isActive ? "Close manual" : "Open the in-product manual")
        .accessibilityLabel(isActive ? "Close manual" : "Open manual")
    }
}
