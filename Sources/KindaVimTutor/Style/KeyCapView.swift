import SwiftUI

struct KeyCapView: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(.body, design: .monospaced, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.background)
                    .shadow(color: .primary.opacity(0.15), radius: 0, x: 0, y: 1)
                    .overlay {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(.primary.opacity(0.2), lineWidth: 1)
                    }
            }
    }
}
