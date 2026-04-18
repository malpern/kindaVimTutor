import SwiftUI
import AppKit

struct ExerciseEditorView: NSViewRepresentable {
    let initialText: String
    let initialCursorPosition: Int
    var resetToken: Int = 0
    var isActive: Bool = true
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
        Self.styleCommentLines(textView)
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

        // Seed the coordinator's reset token so the first updateNSView doesn't
        // re-reset the content we just set above.
        context.coordinator.lastResetToken = resetToken

        if isActive {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                textView.window?.makeFirstResponder(textView)
            }
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        context.coordinator.onFocusChange = onFocusChange

        let initialTextChanged = context.coordinator.currentInitialText != initialText
        let resetRequested = context.coordinator.lastResetToken != resetToken
        if initialTextChanged || resetRequested {
            context.coordinator.currentInitialText = initialText
            context.coordinator.lastResetToken = resetToken
            context.coordinator.isResetting = true
            textView.string = initialText
            Self.styleCommentLines(textView)
            let safePosition = min(initialCursorPosition, textView.string.count)
            textView.setSelectedRange(NSRange(location: safePosition, length: 0))
            context.coordinator.isResetting = false
        }

        if context.coordinator.lastIsActive != isActive {
            context.coordinator.lastIsActive = isActive
            DispatchQueue.main.async {
                guard let window = textView.window else { return }
                if isActive {
                    window.makeFirstResponder(textView)
                } else if window.firstResponder === textView {
                    window.makeFirstResponder(nil)
                }
            }
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
        var lastResetToken: Int = 0
        var lastIsActive: Bool?
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
            ExerciseEditorView.styleCommentLines(textView)
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

    /// Dim lines that start with `//` so in-canvas instructions visually
    /// recede from the target material the learner is manipulating.
    @MainActor
    static func styleCommentLines(_ textView: NSTextView) {
        guard let storage = textView.textStorage else { return }
        let fullRange = NSRange(location: 0, length: storage.length)
        let baseAttrs: [NSAttributedString.Key: Any] = [
            .font: Typography.editorFont,
            .foregroundColor: NSColor.labelColor,
        ]
        storage.setAttributes(baseAttrs, range: fullRange)

        let dimAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.secondaryLabelColor.withAlphaComponent(0.55),
            .obliqueness: NSNumber(value: 0.08),
        ]
        let nsText = storage.string as NSString
        nsText.enumerateSubstrings(in: fullRange, options: .byLines) { line, lineRange, _, _ in
            guard let line else { return }
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("//") {
                storage.addAttributes(dimAttrs, range: lineRange)
            }
        }
    }
}
