import SwiftUI

/// Renders a keyboard key in the style of Keystroke Pro:
/// dark rounded rectangle with concave top surface, subtle inner
/// highlight, bottom depth shadow, clean centered label.
struct KeyCapView: View {
    let label: String
    var size: KeyCapSize = .regular

    enum KeyCapSize {
        case small, regular, large

        var font: Font {
            switch self {
            case .small: .system(size: 11, weight: .medium, design: .rounded)
            case .regular: .system(size: 14, weight: .medium, design: .rounded)
            case .large: .system(size: 20, weight: .medium, design: .rounded)
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

    var body: some View {
        Text(label)
            .font(size.font)
            .foregroundStyle(labelColor)
            .frame(minWidth: size.minWidth, minHeight: size.height)
            .background {
                RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                    .fill(fillColor)
            }
            .overlay {
                RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 0.5)
            }
    }
}
