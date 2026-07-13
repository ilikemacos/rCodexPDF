import SwiftUI
import PDFKit

struct PDFThumbnailSidebar: View {
    @ObservedObject var doc: OpenPDFDocument

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(0..<doc.service.document.pageCount, id: \.self) { index in
                    ThumbnailCell(doc: doc, index: index)
                }
            }
            .padding(8)
        }
        .background(.regularMaterial)
    }
}

private struct ThumbnailCell: View {
    @ObservedObject var doc: OpenPDFDocument
    let index: Int
    @State private var image: NSImage?

    var isCurrent: Bool { doc.currentPageIndex == index }

    var body: some View {
        VStack(spacing: 4) {
            Group {
                if let image {
                    Image(nsImage: image).resizable().aspectRatio(contentMode: .fit)
                } else {
                    Rectangle().fill(Color.gray.opacity(0.15))
                }
            }
            .frame(height: 130)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(isCurrent ? Color.accentColor : .clear, lineWidth: 2))
            Text("\(index + 1)").font(.caption2).foregroundStyle(.secondary)
        }
        .onTapGesture { doc.goToPage(index) }
        .task {
            if image == nil {
                image = doc.service.thumbnail(forPage: index, size: CGSize(width: 140, height: 180))
            }
        }
    }
}
