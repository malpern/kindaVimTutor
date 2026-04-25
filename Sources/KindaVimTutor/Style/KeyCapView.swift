import SwiftUI

/// Renders a keyboard key in the style of Keystroke Pro:
/// dark rounded rectangle with concave top surface, subtle inner
/// highlight, bottom depth shadow, clean centered label.
struct KeyCapView: View {
    let label: String
    var size: KeyCapSize = .regular

    enum KeyCapSize {
        case small, regular, large

        // Monospaced design so `0` (digit) and `O` (letter) are
        // visually distinct on the cap — SF Mono renders zero with a
        // slash. Rounded design flattened them to the same glyph.
        var font: Font {
            switch self {
            case .small: .system(size: 11, weight: .medium, design: .monospaced)
            case .regular: .system(size: 14, weight: .medium, design: .monospaced)
            case .large: .system(size: 20, weight: .medium, design: .monospaced)
            }
        }

        var height: CGFloat {
            switch self {
            case .small: 22
            case .regular: 32
            case .large: 44
            }
        }

        var minWidth: CGFloat {
            switch self {
            case .small: 22
            case .regular: 32
            case .large: 44
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .small: 6
            case .regular: 8
            case .large: 11
            }
        }

        var depthOffset: CGFloat {
            switch self {
            case .small: 1.5
            case .regular: 2
            case .large: 3
            }
        }
    }

    // Flat, typographic palette — keeps the keycap readable without
    // competing with the surrounding prose.
    private let fillColor = Color.secondary.opacity(0.14)
    private let borderColor = Color.secondary.opacity(0.30)
    private let labelColor = Color(white: 0.88)

    /// Observes the shared tracker so the cap can react while the
    /// matching key is physically held down.
    @State private var tracker = KeyPressTracker.shared

    private var isPressed: Bool { tracker.isPressed(label) }

    var body: some View {
        Text(label)
            .font(size.font)
            .foregroundStyle(isPressed ? .white : labelColor)
            .frame(minWidth: size.minWidth, minHeight: size.height)
            .background {
                RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                    .fill(isPressed ? Color.accentColor.opacity(0.42) : fillColor)
            }
            .overlay {
                RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                    .strokeBorder(isPressed ? Color.accentColor : borderColor,
                                  lineWidth: isPressed ? 1.0 : 0.5)
            }
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .shadow(color: isPressed ? Color.accentColor.opacity(0.5) : .clear,
                    radius: isPressed ? 8 : 0)
            .animation(.easeOut(duration: 0.08), value: isPressed)
    }
}
