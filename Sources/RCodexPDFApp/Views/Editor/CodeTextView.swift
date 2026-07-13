import SwiftUI
import AppKit
import RCodexPDFCore

/// An `NSTextView` that recognizes clicks on a folded-block placeholder and restores the
/// original text, since AppKit has no public "hidden range" API for real text folding.
final class FoldingTextView: NSTextView {
    var foldedBlocks: [(placeholderRange: NSRange, original: NSAttributedString)] = []
    var onUnfold: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        guard let layoutManager, let container = textContainer else {
            super.mouseDown(with: event)
            return
        }
        let point = convert(event.locationInWindow, from: nil)
        let charIndex = layoutManager.characterIndex(for: point, in: container, fractionOfDistanceBetweenInsertionPoints: nil)

        if let hitIndex = foldedBlocks.firstIndex(where: { NSLocationInRange(charIndex, $0.placeholderRange) }) {
            let block = foldedBlocks.remove(at: hitIndex)
            textStorage?.beginEditing()
            textStorage?.replaceCharacters(in: block.placeholderRange, with: block.original)
            textStorage?.endEditing()
            didChangeText()
            onUnfold?()
            return
        }
        super.mouseDown(with: event)
    }
}

struct CodeTextView: NSViewRepresentable {
    @Binding var text: String
    let language: ProgrammingLanguage?
    let theme: EditorTheme
    let fontSize: Double

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = FoldingTextView()
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isRichText = false
        textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.allowsUndo = true
        textView.textContainerInset = NSSize(width: 6, height: 8)
        textView.string = text
        textView.onUnfold = { [weak coordinator = context.coordinator] in
            coordinator?.parent.text = textView.string
            coordinator?.highlight()
        }

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true

        let ruler = LineNumberRulerView(textView: textView)
        ruler.onClickLine = { [weak coordinator = context.coordinator] line in
            coordinator?.toggleFold(atLine: line)
        }
        scrollView.verticalRulerView = ruler
        scrollView.hasHorizontalRuler = false
        scrollView.rulersVisible = true

        context.coordinator.textView = textView
        context.coordinator.applyTheme()
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? FoldingTextView else { return }
        context.coordinator.parent = self
        if textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.string = text
            textView.foldedBlocks.removeAll()
            context.coordinator.highlight()
            textView.setSelectedRange(selectedRange)
        }
        if textView.font?.pointSize != CGFloat(fontSize) {
            textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        }
        context.coordinator.applyTheme()
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CodeTextView
        weak var textView: FoldingTextView?

        init(_ parent: CodeTextView) {
            self.parent = parent
        }

        func applyTheme() {
            guard let textView else { return }
            let palette = SyntaxTheme.palette(for: parent.theme)
            textView.backgroundColor = palette.background
            textView.insertionPointColor = palette.text
            highlight()
        }

        func highlight() {
            guard let textView, let storage = textView.textStorage else { return }
            let palette = SyntaxTheme.palette(for: parent.theme)
            SyntaxHighlighter.highlight(storage, language: parent.language, palette: palette)
        }

        func textDidChange(_ notification: Notification) {
            guard let textView else { return }
            parent.text = textView.string
            highlight()
            highlightMatchingBracket()
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            highlightMatchingBracket()
        }

        private func highlightMatchingBracket() {
            guard let textView, let storage = textView.textStorage else { return }
            let fullRange = NSRange(location: 0, length: storage.length)
            storage.removeAttribute(.backgroundColor, range: fullRange)

            let selected = textView.selectedRange()
            guard selected.length == 0, selected.location > 0 else { return }
            let text = storage.string as NSString
            let pairs: [Character: Character] = ["(": ")", "[": "]", "{": "}"]
            let reversePairs: [Character: Character] = [")": "(", "]": "[", "}": "{"]

            let cursorIndex = selected.location
            guard cursorIndex <= text.length, cursorIndex > 0 else { return }
            let charBefore = Character(text.substring(with: NSRange(location: cursorIndex - 1, length: 1)))

            if let open = pairs[charBefore] {
                if let matchIndex = findMatch(open: charBefore, close: open, from: cursorIndex, forward: true, in: text) {
                    let color = NSColor.systemYellow.withAlphaComponent(0.3)
                    storage.addAttribute(.backgroundColor, value: color, range: NSRange(location: cursorIndex - 1, length: 1))
                    storage.addAttribute(.backgroundColor, value: color, range: NSRange(location: matchIndex, length: 1))
                }
            } else if let open = reversePairs[charBefore] {
                if let matchIndex = findMatch(open: open, close: charBefore, from: cursorIndex - 1, forward: false, in: text) {
                    let color = NSColor.systemYellow.withAlphaComponent(0.3)
                    storage.addAttribute(.backgroundColor, value: color, range: NSRange(location: cursorIndex - 1, length: 1))
                    storage.addAttribute(.backgroundColor, value: color, range: NSRange(location: matchIndex, length: 1))
                }
            }
        }

        private func findMatch(open: Character, close: Character, from: Int, forward: Bool, in text: NSString) -> Int? {
            var depth = 0
            if forward {
                var i = from
                while i < text.length {
                    let c = Character(text.substring(with: NSRange(location: i, length: 1)))
                    if c == open { depth += 1 }
                    if c == close {
                        if depth == 0 { return i }
                        depth -= 1
                    }
                    i += 1
                }
            } else {
                var i = from - 1
                while i >= 0 {
                    let c = Character(text.substring(with: NSRange(location: i, length: 1)))
                    if c == close { depth += 1 }
                    if c == open {
                        if depth == 0 { return i }
                        depth -= 1
                    }
                    i -= 1
                }
            }
            return nil
        }

        // MARK: - Completion (native NSTextView completion mechanism, Esc / Option-Esc / on-type)

        func textView(
            _ textView: NSTextView,
            completions words: [String],
            forPartialWordRange charRange: NSRange,
            indexOfSelectedItem index: UnsafeMutablePointer<Int>?
        ) -> [String] {
            let partial = (textView.string as NSString).substring(with: charRange)
            return SyntaxHighlighter.completions(for: parent.language, text: textView.string, partialWord: partial)
        }

        // MARK: - Code folding
        // Collapses the `{ ... }` block starting on `lineNumber` into a " ⋯ " placeholder.
        // Clicking the placeholder (handled by `FoldingTextView.mouseDown`) restores it.

        func toggleFold(atLine lineNumber: Int) {
            guard let textView, let storage = textView.textStorage else { return }
            let text = storage.string as NSString

            var currentLine = 1
            var idx = 0
            var lineStart = -1
            while idx < text.length {
                let range = text.lineRange(for: NSRange(location: idx, length: 0))
                if currentLine == lineNumber {
                    lineStart = range.location
                    break
                }
                idx = range.location + max(range.length, 1)
                currentLine += 1
            }
            guard lineStart >= 0 else { return }

            let lineRange = text.lineRange(for: NSRange(location: lineStart, length: 0))
            let braceLocation = text.range(of: "{", options: [], range: lineRange).location
            guard braceLocation != NSNotFound else { return }

            guard let closeIndex = findMatch(open: "{", close: "}", from: braceLocation + 1, forward: true, in: text) else { return }
            let foldRange = NSRange(location: braceLocation + 1, length: closeIndex - (braceLocation + 1))
            guard foldRange.length > 1 else { return }

            let original = storage.attributedSubstring(from: foldRange)
            let placeholder = NSAttributedString(
                string: " ⋯ ",
                attributes: [.foregroundColor: NSColor.secondaryLabelColor, .backgroundColor: NSColor.secondaryLabelColor.withAlphaComponent(0.15)]
            )
            storage.beginEditing()
            storage.replaceCharacters(in: foldRange, with: placeholder)
            storage.endEditing()

            textView.foldedBlocks.append((NSRange(location: foldRange.location, length: placeholder.length), original))
            parent.text = textView.string
            highlight()
        }
    }
}
