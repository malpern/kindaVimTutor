import SwiftUI

struct KeyCapView: View {
    let label: String
    var size: KeyCapSize = .regular

    enum KeyCapSize {
        case regular, large

        var font: Font {
            switch self {
            case .regular: Typography.keyCap
            case .large: Typography.keyCapLarge
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .regular: 8
            case .large: 10
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .regular: 4
            case .large: 6
            }
        }
    }

    var body: some View {
        Text(label)
            .font(size.font)
            .foregroundStyle(.primary)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.primary.opacity(0.06))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(.primary.opacity(0.15), lineWidth: 1)
                    }
            }
    }
}
