import SwiftUI

/// Visualizes Vim's operator × motion grammar as a 2D table so the
/// multiplicative nature ("a few operators × a few motions = dozens
/// of commands") reads at a glance. Rows = operators, columns =
/// motions, each cell shows the combined command's plain-English
/// meaning.
struct GrammarGridView: View {
    private struct Operator {
        let key: String
        let verb: String
    }

    private struct Motion {
        let key: String
        let name: String
    }

    private static let operators: [Operator] = [
        .init(key: "d", verb: "delete"),
        .init(key: "c", verb: "change"),
        .init(key: "y", verb: "yank"),
    ]

    private static let motions: [Motion] = [
        .init(key: "w", name: "word"),
        .init(key: "e", name: "to word end"),
        .init(key: "$", name: "to end of line"),
        .init(key: "0", name: "to start of line"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            headerRow
            ForEach(Self.operators, id: \.key) { op in
                row(for: op)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            Text("")
                .frame(width: cornerWidth, height: headerHeight)
            ForEach(Self.motions, id: \.key) { m in
                VStack(spacing: 2) {
                    KeyCapView(label: m.key, size: .small)
                    Text(m.name)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, minHeight: headerHeight)
            }
        }
        .background(Color.white.opacity(0.03))
    }

    private func row(for op: Operator) -> some View {
        HStack(spacing: 0) {
            VStack(spacing: 2) {
                KeyCapView(label: op.key, size: .small)
                Text(op.verb)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            .frame(width: cornerWidth, height: cellHeight)
            .background(Color.white.opacity(0.03))

            ForEach(Self.motions, id: \.key) { m in
                cell(op: op, motion: m)
                    .frame(maxWidth: .infinity, minHeight: cellHeight)
                    .overlay(
                        Rectangle()
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 1),
                        alignment: .leading
                    )
            }
        }
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1),
            alignment: .top
        )
    }

    private func cell(op: Operator, motion: Motion) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 2) {
                Text(op.key)
                    .foregroundStyle(Color.accentColor)
                Text(motion.key)
                    .foregroundStyle(Color.accentColor.opacity(0.75))
            }
            .font(.system(size: 14, weight: .semibold, design: .monospaced))

            Text("\(op.verb) \(motion.name)")
                .font(.system(size: 10))
                .foregroundStyle(.primary.opacity(0.75))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }

    private let cornerWidth: CGFloat = 64
    private let headerHeight: CGFloat = 48
    private let cellHeight: CGFloat = 54
}
