import SwiftUI

/// Side-by-side comparison of `f` and `t` on identical text: both
/// search for the same character, but `f` lands ON it while `t`
/// stops one character BEFORE. Rendering the two outcomes on the
/// same sample sentence makes the subtle distinction legible in
/// a way prose can't.
struct FindVsTillView: View {
    /// The sample text used for both rows. Short enough to read at
    /// a glance; has multiple instances of the target so the "first
    /// match, left-to-right" rule shows too.
    private static let text: String = "the quick brown fox"
    private static let target: Character = "o"

    /// First `o` in the text — where `f`o lands; where `t`o stops
    /// one short of.
    private static var firstTargetIndex: Int {
        text.firstIndex(of: target).map { text.distance(from: text.startIndex, to: $0) } ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            row(
                command: ("f", "o"),
                caption: "lands ON the 'o'",
                cursorIndex: Self.firstTargetIndex
            )
            row(
                command: ("t", "o"),
                caption: "stops BEFORE the 'o'",
                cursorIndex: max(Self.firstTargetIndex - 1, 0)
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func row(command: (String, String), caption: String, cursorIndex: Int) -> some View {
        HStack(alignment: .center, spacing: 14) {
            HStack(spacing: 4) {
                KeyCapView(label: command.0, size: .small)
                KeyCapView(label: command.1, size: .small)
            }
            .frame(width: 70, alignment: .leading)

            annotatedText(cursorIndex: cursorIndex)

            Text(caption)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Renders the sample text with a block cursor highlighting the
    /// character the given command lands on. Monospace so glyph
    /// widths match across rows and the cursor alignment reads
    /// consistently.
    private func annotatedText(cursorIndex: Int) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(Self.text.enumerated()), id: \.offset) { index, char in
                let isCursor = index == cursorIndex
                let isTarget = char == Self.target
                Text(String(char))
                    .font(.system(size: 15, weight: .regular, design: .monospaced))
                    .foregroundStyle(
                        isCursor ? Color(nsColor: .windowBackgroundColor)
                                 : (isTarget ? Color.accentColor : Color.primary.opacity(0.85))
                    )
                    .frame(width: 11, height: 22)
                    .background(
                        isCursor
                            ? AnyShapeStyle(Color.accentColor)
                            : AnyShapeStyle(Color.clear),
                        in: RoundedRectangle(cornerRadius: 2)
                    )
            }
        }
    }
}
