import SwiftUI

/// A compact QWERTY home-row visualization. Keys in `highlighted` are
/// drawn with the accent color so "these four keys are right under
/// your hand" reads instantly instead of demanding visual memory.
struct HomeRowView: View {
    let highlighted: [String]

    private static let keys: [String] = ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";"]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Self.keys, id: \.self) { key in
                keyView(for: key)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func keyView(for key: String) -> some View {
        let isActive = highlighted.contains(key)
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isActive ? Color.accentColor.opacity(0.22) : Color.white.opacity(0.04))
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(isActive ? Color.accentColor.opacity(0.75)
                                        : Color.white.opacity(0.12),
                              lineWidth: 1)
            Text(key)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(isActive ? Color.accentColor : Color.secondary)
        }
        .frame(width: 34, height: 34)
    }
}
