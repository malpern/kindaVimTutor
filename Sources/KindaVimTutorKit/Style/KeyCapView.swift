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

    // Keystroke Pro palette
    private let faceTop = Color(red: 0.26, green: 0.26, blue: 0.28)
    private let faceBottom = Color(red: 0.20, green: 0.20, blue: 0.22)
    private let sideColor = Color(red: 0.14, green: 0.14, blue: 0.16)
    private let highlightTop = Color.white.opacity(0.12)
    private let highlightBottom = Color.white.opacity(0.02)
    private let labelColor = Color(white: 0.88)

    var body: some View {
        Text(label)
            .font(size.font)
            .foregroundStyle(labelColor)
            .frame(minWidth: size.minWidth, minHeight: size.height)
            .background {
                ZStack {
                    // Side/depth layer — visible below the face
                    RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                        .fill(sideColor)
                        .offset(y: size.depthOffset)

                    // Key face — slight top-to-bottom gradient for concave feel
                    RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [faceTop, faceBottom],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Inner highlight — top edge catch
                    RoundedRectangle(cornerRadius: size.cornerRadius - 0.5, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [highlightTop, highlightBottom],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.75
                        )
                        .padding(0.5)
                }
            }
            // Outer glow/shadow — key floating above surface
            .shadow(color: .black.opacity(0.35), radius: 3, y: 2)
            .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
    }
}

#Preview("Sizes") {
    HStack(spacing: 12) {
        KeyCapView(label: "esc", size: .small)
        KeyCapView(label: "L", size: .regular)
        KeyCapView(label: "space", size: .large)
    }
    .padding()
    .background(Color(white: 0.94))
}
