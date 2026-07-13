import Foundation
import PDFKit

/// Lightweight, `Sendable` mirror of `PDFOutline` (which is not `Sendable`), used to hand the
/// bookmark/outline tree to SwiftUI views and the CLI without crossing actor boundaries unsafely.
public struct PDFOutlineNode: Identifiable, Sendable {
    public let id = UUID()
    public let label: String
    public let pageIndex: Int?
    public let children: [PDFOutlineNode]

    public init(label: String, pageIndex: Int?, children: [PDFOutlineNode]) {
        self.label = label
        self.pageIndex = pageIndex
        self.children = children
    }

    public static func build(from outline: PDFOutline?, document: PDFDocument) -> [PDFOutlineNode] {
        guard let outline else { return [] }
        var nodes: [PDFOutlineNode] = []
        for index in 0..<outline.numberOfChildren {
            guard let child = outline.child(at: index) else { continue }
            let pageIndex = child.destination?.page.flatMap { document.index(for: $0) }
            let children = build(from: child, document: document)
            nodes.append(PDFOutlineNode(label: child.label ?? "Untitled", pageIndex: pageIndex, children: children))
        }
        return nodes
    }
}

public struct PDFSearchResult: Identifiable, Sendable {
    public let id = UUID()
    public let pageIndex: Int
    public let snippet: String
    public let boundsInPage: CGRect
}
