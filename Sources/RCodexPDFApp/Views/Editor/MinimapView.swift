import SwiftUI
import AppKit

/// A miniature, non-editable rendering of the document at a tiny font size, common in modern
/// code editors as a scroll overview. Clicking jumps the main editor to that position.
struct MinimapView: NSViewRepresentable {
    let text: String
    let onJump: (CGFloat) -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = false
        textView.font = .monospacedSystemFont(ofSize: 2, weight: .regular)
        textView.textColor = .secondaryLabelColor
        textView.backgroundColor = .clear
        textView.textContainerInset = NSSize(width: 2, height: 4)

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false

        let click = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleClick(_:)))
        scrollView.addGestureRecognizer(click)
        context.coordinator.scrollView = scrollView
        context.coordinator.onJump = onJump
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
        context.coordinator.onJump = onJump
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject {
        weak var scrollView: NSScrollView?
        var onJump: ((CGFloat) -> Void)?

        @objc func handleClick(_ sender: NSClickGestureRecognizer) {
            guard let scrollView else { return }
            let location = sender.location(in: scrollView)
            let fraction = location.y / max(scrollView.bounds.height, 1)
            onJump?(fraction)
        }
    }
}
