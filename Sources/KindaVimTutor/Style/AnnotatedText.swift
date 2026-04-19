import SwiftUI

/// Renders a string with backtick-wrapped tokens rendered as `KeyCapView`s
/// inline with the surrounding text, wrapping naturally across lines.
///
///     AnnotatedText("Press `j` then `x` to delete")
///
/// Text chunks and keycaps are laid out by `WrapLayout`, which packs
/// subviews horizontally and wraps to the next row when the container's
/// width is exceeded.
struct AnnotatedText: View {
    let string: String
    var font: Font = .system(size: 18, weight: .regular)
    var capSize: KeyCapView.KeyCapSize = .small
    var foregroundStyle: Color? = nil

    var body: some View {
        WrapLayout(hSpacing: 4, vSpacing: 6) {
            ForEach(Array(Self.segments(from: string).enumerated()), id: \.offset) { _, seg in
                switch seg {
                case .text(let s):
                    Text(s)
                        .font(font)
                        .lineSpacing(4)
                        .foregroundStyle(foregroundStyle ?? .primary)
                case .key(let k):
                    KeyCapView(label: k, size: capSize)
                }
            }
        }
    }

    // MARK: - Segmentation

    enum Segment: Equatable {
        case text(String)
        case key(String)
    }

    static func segments(from input: String) -> [Segment] {
        var out: [Segment] = []
        var cursor = input.startIndex
        while cursor < input.endIndex {
            guard let open = input[cursor...].firstIndex(of: "`") else {
                out.append(.text(String(input[cursor...])))
                break
            }
            if open > cursor {
                out.append(.text(String(input[cursor..<open])))
            }
            let afterOpen = input.index(after: open)
            guard let close = input[afterOpen...].firstIndex(of: "`") else {
                // Unterminated backtick — treat the rest as text.
                out.append(.text(String(input[open...])))
                break
            }
            let token = String(input[afterOpen..<close])
            if !token.isEmpty {
                out.append(.key(token))
            }
            cursor = input.index(after: close)
        }
        // Split each text segment on word boundaries so the layout can
        // wrap naturally between words, not just between segments.
        return out.flatMap { seg -> [Segment] in
            guard case .text(let s) = seg else { return [seg] }
            return explodeWords(s)
        }
    }

    private static func explodeWords(_ s: String) -> [Segment] {
        var parts: [Segment] = []
        var buf = ""
        for ch in s {
            buf.append(ch)
            if ch == " " {
                parts.append(.text(buf))
                buf = ""
            }
        }
        if !buf.isEmpty { parts.append(.text(buf)) }
        return parts
    }
}

/// Lays out subviews in a horizontal row, wrapping to the next row when
/// the proposed width is exceeded.
struct WrapLayout: Layout {
    var hSpacing: CGFloat = 4
    var vSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for sv in subviews {
            let size = sv.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + vSpacing
                totalWidth = max(totalWidth, rowWidth)
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + (rowWidth > 0 ? hSpacing : 0)
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        totalWidth = max(totalWidth, rowWidth)
        return CGSize(width: min(totalWidth, maxWidth), height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for sv in subviews {
            let size = sv.sizeThatFits(.unspecified)
            if x + size.width > bounds.minX + maxWidth, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + vSpacing
                rowHeight = 0
            }
            sv.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: .unspecified)
            x += size.width + hSpacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
