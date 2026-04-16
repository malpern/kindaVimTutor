import SwiftUI
import AppKit

struct ExerciseEditorView: NSViewRepresentable {
    let initialText: String
    let initialCursorPosition: Int
    var onTextChange: (String, Int) -> Void
    var onSelectionChange: (String, Int) -> Void
    var onFocusChange: ((Bool) -> Void)?

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

        // Typography — standard system text
        textView.font = Typography.editorFont
        textView.textColor = .labelColor
        textView.insertionPointColor = .controlAccentColor
        textView.backgroundColor = NSColor(AppColors.editorBackground)

        // Generous interior spacing
        textView.textContainerInset = NSSize(width: 16, height: 14)
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
        context.coordinator.textView = textView
        context.coordinator.onFocusChange = onFocusChange

        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        // Auto-focus the editor after a brief delay (lets the view settle)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            textView.window?.makeFirstResponder(textView)
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        context.coordinator.onFocusChange = onFocusChange
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

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var onTextChange: (String, Int) -> Void
        var onSelectionChange: (String, Int) -> Void
        var onFocusChange: ((Bool) -> Void)?
        var currentInitialText: String
        var isResetting = false
        weak var textView: NSTextView?
        private var lastFocusState: Bool?

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
            checkFocusState()
        }

        nonisolated func textDidBeginEditing(_ notification: Notification) {
            MainActor.assumeIsolated {
                onFocusChange?(true)
                lastFocusState = true
            }
        }

        nonisolated func textDidEndEditing(_ notification: Notification) {
            MainActor.assumeIsolated {
                onFocusChange?(false)
                lastFocusState = false
            }
        }

        private func checkFocusState() {
            let isFocused = textView?.window?.firstResponder === textView
            if isFocused != lastFocusState {
                lastFocusState = isFocused
                onFocusChange?(isFocused)
            }
        }

        func resetToInitial() {
            guard let textView else { return }
            isResetting = true
            textView.string = currentInitialText
            textView.setSelectedRange(NSRange(location: 0, length: 0))
            isResetting = false
        }
    }
}
