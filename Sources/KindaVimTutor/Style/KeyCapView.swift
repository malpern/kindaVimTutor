import SwiftUI

struct KeyCapView: View {
    let label: String
    var size: KeyCapSize = .regular

    enum KeyCapSize {
        case small, regular, large

        var font: Font {
            switch self {
            case .small: .system(size: 12, weight: .bold, design: .monospaced)
            case .regular: .system(size: 14, weight: .bold, design: .monospaced)
            case .large: .system(size: 18, weight: .bold, design: .monospaced)
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small: 6
            case .regular: 10
            case .large: 14
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .small: 3
            case .regular: 6
            case .large: 8
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .small: 5
            case .regular: 7
            case .large: 9
            }
        }

        var minWidth: CGFloat {
            switch self {
            case .small: 22
            case .regular: 30
            case .large: 38
            }
        }
    }

    var body: some View {
        Text(label)
            .font(size.font)
            .foregroundStyle(.primary)
            .frame(minWidth: size.minWidth)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background {
                ZStack {
                    // Bottom shadow layer (the "depth" of the key)
                    RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                        .fill(.primary.opacity(0.12))
                        .offset(y: 2)

                    // Main key surface
                    RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(white: 0.28),
                                    Color(white: 0.22),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Top highlight
                    RoundedRectangle(cornerRadius: size.cornerRadius - 1, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.15),
                                    .white.opacity(0.03),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                        .padding(0.5)
                }
            }
            .foregroundStyle(.white)
    }
}
