import SwiftUI
import AppKit

/// Prose paragraph describing the Vim mode flip cycle, with the same
/// INSERT/NORMAL chips used in the live indicator embedded inline with
/// the text. Rendered via a single `Text` concatenation + `ImageRenderer`
/// snapshots of `ModeIndicatorView` so the chips flow with word wrap.
struct ModeFlowNarrativeView: View {
    var body: some View {
        let insert = Self.chipImage(for: .insert)
        let normal = Self.chipImage(for: .normal)

        let gap = Text(" ")

        let base = Text("When you click into a text field, kindaVim starts in")
            + gap + Self.chipText(insert)
            + Text(" — keys type text. Press Esc to flip into")
            + gap + Self.chipText(normal)
            + Text(" — now Vim motions move the cursor. Press i when you need to type again —")
            + gap + Self.chipText(insert)
            + Text(". Press Esc to stop — back to")
            + gap + Self.chipText(normal)
            + Text(".")

        base
            .font(.system(size: 15))
            .foregroundStyle(.primary.opacity(0.85))
            .lineSpacing(5)
    }

    /// Snapshot a `ModeIndicatorView` to an NSImage so it can ride inline
    /// inside a `Text` via `Text(Image(nsImage:))`.
    @MainActor
    private static func chipImage(for mode: VimMode) -> NSImage? {
        let view = ModeIndicatorView(mode: mode, isKindaVimRunning: true)
            .padding(2)
        let renderer = ImageRenderer(content: view)
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2.0
        return renderer.nsImage
    }

    private static func chipText(_ image: NSImage?) -> Text {
        guard let image else { return Text("") }
        return Text(Image(nsImage: image))
            .baselineOffset(-4)
    }
}
