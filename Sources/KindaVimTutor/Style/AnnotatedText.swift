import SwiftUI

/// Renders a string with inline tokens expanded into styled runs that
/// flow with surrounding prose.
///
///     AnnotatedText("Press `j` to move left")
///     AnnotatedText("Switch to {{normal}} — keys become commands")
///
/// Supported tokens:
///   `key`           → bold monospace run for a key like `Esc`, `i`, `dd`
///   {{normal}},
///   {{insert}},
///   {{visual}}      → `InlineModeChip` (rounded pill) for the named
///                    kindaVim mode
///
/// Two rendering paths:
///   - If the string has no mode tokens, builds a single
///     `Text(AttributedString)` — native line-break, no custom layout.
///   - If it has a mode token, uses `AnnotatedFlow` (a custom `Layout`)
///     so the pill-shaped chip can flow inline with text runs.
///
/// The custom `Layout` is safe here because our app shell is a plain
/// `HStack { Sidebar | Divider | Detail }` rather than a
/// `NavigationSplitView`. macOS 26's NSV will cascade window-level
/// re-layout when a custom `Layout` is used inside the detail pane —
/// see 2026-04-22/23 bisection. Keeping NSV off means chips are free.
struct AnnotatedText: View {
    let string: String
    var font: Font = .system(size: 18, weight: .regular)
    var capSize: KeyCapView.KeyCapSize = .small
    var foregroundStyle: Color? = nil

    var body: some View {
        let segments = Self.segments(from: string)
        if segments.contains(where: { if case .mode = $0 { true } else { false } }) {
            AnnotatedFlow(hSpacing: 0, vSpacing: 6) {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, seg in
                    switch seg {
                    case .text(let s):
                        Text(s)
                            .font(font)
                            .lineSpacing(6)
                            .foregroundStyle(foregroundStyle ?? .primary)
                    case .key(let k):
                        Text(k)
                            .font(capSize.inlineFont)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary.opacity(0.88))
                    case .mode(let m):
                        InlineModeChip(mode: m)
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(attributedString(for: segments))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func attributedString(for segments: [Segment]) -> AttributedString {
        var out = AttributedString("")
        for segment in segments {
            out.append(run(for: segment))
        }
        return out
    }

    private func run(for segment: Segment) -> AttributedString {
        switch segment {
        case .text(let string):
            var run = AttributedString(string)
            run.font = font
            run.foregroundColor = foregroundStyle ?? .primary
            return run

        case .key(let key):
            var run = AttributedString(key)
            run.font = capSize.inlineFont
            run.foregroundColor = .primary.opacity(0.92)
            return run

        case .mode(let mode):
            // Not used on this path — mode-bearing strings take the
            // AnnotatedFlow branch — but keep the run for parser
            // symmetry.
            var run = AttributedString(mode.displayName)
            run.font = .system(.caption, design: .monospaced, weight: .bold)
            run.foregroundColor = mode.color
            return run
        }
    }

    // MARK: - Segmentation

    enum Segment: Equatable {
        case text(String)
        case key(String)
        case mode(VimMode)
    }

    /// Walks the string once, pulling out keycap and mode tokens in a
    /// single pass so either kind can appear in any order.
    static func segments(from input: String) -> [Segment] {
        var out: [Segment] = []
        var buffer = ""
        var i = input.startIndex

        func flushBuffer() {
            if !buffer.isEmpty {
                out.append(.text(buffer))
                buffer = ""
            }
        }

        while i < input.endIndex {
            // Keycap token: `...`
            if input[i] == "`" {
                let afterOpen = input.index(after: i)
                if let close = input[afterOpen...].firstIndex(of: "`") {
                    flushBuffer()
                    let token = String(input[afterOpen..<close])
                    if !token.isEmpty { out.append(.key(token)) }
                    i = input.index(after: close)
                    continue
                }
            }

            // Mode token: {{name}}
            if input[i] == "{", tail(from: i, in: input).hasPrefix("{{") {
                let afterOpen = input.index(i, offsetBy: 2)
                if let close = input.range(of: "}}", range: afterOpen..<input.endIndex) {
                    flushBuffer()
                    let token = String(input[afterOpen..<close.lowerBound])
                        .trimmingCharacters(in: .whitespaces)
                        .lowercased()
                    if let mode = modeFromToken(token) {
                        out.append(.mode(mode))
                    }
                    i = close.upperBound
                    continue
                }
            }

            buffer.append(input[i])
            i = input.index(after: i)
        }
        flushBuffer()

        return out.flatMap { seg -> [Segment] in
            guard case .text(let s) = seg else { return [seg] }
            return explodeWords(s)
        }
    }

    private static func tail(from index: String.Index, in s: String) -> Substring {
        s[index...]
    }

    private static func modeFromToken(_ token: String) -> VimMode? {
        switch token {
        case "normal": return .normal
        case "insert": return .insert
        case "visual": return .visual
        default:       return nil
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

private extension KeyCapView.KeyCapSize {
    var inlineFont: Font {
        switch self {
        case .small: .system(size: 13, weight: .semibold, design: .monospaced)
        case .regular: .system(size: 15, weight: .semibold, design: .monospaced)
        case .large: .system(size: 20, weight: .semibold, design: .monospaced)
        }
    }
}

/// Compact inline chip used inside prose. Smaller than the toolbar
/// badge so it sits on a normal text line without dominating it.
struct InlineModeChip: View {
    let mode: VimMode

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(mode.color)
                .frame(width: 6, height: 6)
            Text(mode.displayName)
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background {
            Capsule().fill(mode.color.opacity(0.18))
        }
        .overlay {
            Capsule().strokeBorder(mode.color.opacity(0.40), lineWidth: 0.5)
        }
        .accessibilityLabel("\(mode.displayName) mode")
    }
}

/// Inline flow layout used by AnnotatedText for mode-chip strings.
/// Each subview is asked for its intrinsic size once and then placed
/// with wrap-on-overflow. Safe to use here because the app shell is
/// a plain `HStack`, not a `NavigationSplitView` — the layout cascade
/// macOS 26 produces under NSV with custom `Layout` is not in play.
struct AnnotatedFlow: Layout {
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
