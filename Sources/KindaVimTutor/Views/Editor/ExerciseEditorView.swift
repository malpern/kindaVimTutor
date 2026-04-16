import SwiftUI
import AppKit

struct ExerciseEditorView: NSViewRepresentable {
    let initialText: String
    let initialCursorPosition: Int
    var onTextChange: (String, Int) -> Void
    var onSelectionChange: (String, Int) -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        // Configure for Vim/kindaVim compatibility
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isGrammarCheckingEnabled = false

        // Typography
        textView.font = Typography.editorFont
        textView.textColor = NSColor.white.withAlphaComponent(0.9)
        textView.insertionPointColor = .white
        textView.backgroundColor = NSColor(white: 0.12, alpha: 1.0)

        // Layout
        textView.textContainerInset = NSSize(width: 12, height: 10)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true

        // Accessibility — critical for kindaVim
        textView.setAccessibilityIdentifier("ExerciseEditor")
        textView.setAccessibilityLabel("Exercise Editor")

        // Set initial content
        textView.string = initialText
        let safePosition = min(initialCursorPosition, textView.string.count)
        textView.setSelectedRange(NSRange(location: safePosition, length: 0))

        // Delegate
        textView.delegate = context.coordinator

        // Store reference for updates
        context.coordinator.textView = textView

        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        // Only reset text when exercise changes (tracked by coordinator)
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if context.coordinator.currentInitialText != initialText {
            context.coordinator.currentInitialText = initialText
            context.coordinator.isResetting = true
            textView.string = initialText
            let safePosition = min(initialCursorPosition, textView.string.count)
            textView.setSelectedRange(NSRange(location: safePosition, length: 0))
            context.coordinator.isResetting = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onTextChange: onTextChange, onSelectionChange: onSelectionChange, initialText: initialText)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var onTextChange: (String, Int) -> Void
        var onSelectionChange: (String, Int) -> Void
        var currentInitialText: String
        var isResetting = false
        weak var textView: NSTextView?

        init(onTextChange: @escaping (String, Int) -> Void,
             onSelectionChange: @escaping (String, Int) -> Void,
             initialText: String) {
            self.onTextChange = onTextChange
            self.onSelectionChange = onSelectionChange
            self.currentInitialText = initialText
        }

        func textDidChange(_ notification: Notification) {
            guard !isResetting, let textView = notification.object as? NSTextView else { return }
            let cursorPosition = textView.selectedRange().location
            onTextChange(textView.string, cursorPosition)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard !isResetting, let textView = notification.object as? NSTextView else { return }
            let cursorPosition = textView.selectedRange().location
            onSelectionChange(textView.string, cursorPosition)
        }

        @MainActor func resetToInitial() {
            guard let textView else { return }
            isResetting = true
            textView.string = currentInitialText
            textView.setSelectedRange(NSRange(location: 0, length: 0))
            isResetting = false
        }
    }
}
