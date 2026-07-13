import AppKit

/// Standard `NSRulerView` line-number gutter for an `NSTextView` inside a scroll view,
/// with a click target per line to toggle code folding.
final class LineNumberRulerView: NSRulerView {
    weak var textView: NSTextView?
    var foldedRanges: [ClosedRange<Int>] = []
    var onClickLine: ((Int) -> Void)?

    init(textView: NSTextView) {
        self.textView = textView
        super.init(scrollView: textView.enclosingScrollView, orientation: .verticalRuler)
        clientView = textView
        ruleThickness = 44
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView, let layoutManager = textView.layoutManager, let container = textView.textContainer else { return }
        let visibleRect = textView.visibleRect
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular),
            .foregroundColor: NSColor.secondaryLabelColor
        ]

        let text = textView.string as NSString
        var lineNumber = 1
        var index = 0
        var lineStart = 0

        while index < text.length {
            let lineRange = text.lineRange(for: NSRange(location: index, length: 0))
            let glyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
            let lineRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: container)
            let yInTextView = lineRect.minY + textView.textContainerInset.height

            if visibleRect.intersects(NSRect(x: 0, y: yInTextView, width: 1, height: lineRect.height)) {
                let numberString = "\(lineNumber)" as NSString
                let size = numberString.size(withAttributes: attributes)
                let point = NSPoint(
                    x: ruleThickness - size.width - 6,
                    y: yInTextView - visibleRect.minY - size.height / 2 + lineRect.height / 2
                )
                numberString.draw(at: point, withAttributes: attributes)
            }

            lineStart = lineRange.location
            index = lineRange.location + max(lineRange.length, 1)
            if lineStart >= text.length { break }
            lineNumber += 1
        }
    }

    override func mouseDown(with event: NSEvent) {
        guard let textView, let layoutManager = textView.layoutManager, let container = textView.textContainer else { return }
        let point = convert(event.locationInWindow, from: nil)
        let textViewPoint = NSPoint(x: 0, y: point.y + textView.visibleRect.minY - textView.textContainerInset.height)
        let charIndex = layoutManager.characterIndex(for: textViewPoint, in: container, fractionOfDistanceBetweenInsertionPoints: nil)
        let text = textView.string as NSString
        let lineRange = text.lineRange(for: NSRange(location: min(charIndex, max(text.length - 1, 0)), length: 0))
        var lineNumber = 1
        var idx = 0
        while idx < lineRange.location {
            let r = text.lineRange(for: NSRange(location: idx, length: 0))
            idx = r.location + max(r.length, 1)
            lineNumber += 1
        }
        onClickLine?(lineNumber)
    }
}
