import SwiftUI
import PDFKit

/// Wraps an already-configured `PDFView` instance (owned by `OpenPDFDocument`) so SwiftUI can
/// host it. The view instance is reused rather than recreated to preserve scroll position, zoom,
/// and PDFKit's own smooth-scrolling render cache.
struct PDFKitRepresentable: NSViewRepresentable {
    let pdfView: PDFView

    func makeNSView(context: Context) -> PDFView {
        pdfView.backgroundColor = .textBackgroundColor
        return pdfView
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        // No-op: PDFView is mutated directly by OpenPDFDocument's methods.
    }
}
