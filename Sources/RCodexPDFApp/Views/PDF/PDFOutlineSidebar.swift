import SwiftUI
import RCodexPDFCore

struct PDFOutlineSidebar: View {
    @ObservedObject var doc: OpenPDFDocument
    @State private var nodes: [PDFOutlineNode] = []

    var body: some View {
        Group {
            if nodes.isEmpty {
                VStack {
                    Spacer()
                    Text("No bookmarks in this document").foregroundStyle(.secondary).font(.caption)
                    Spacer()
                }
            } else {
                List(nodes, children: \.childrenOrNil) { node in
                    Button {
                        if let page = node.pageIndex { doc.goToPage(page) }
                    } label: {
                        Text(node.label)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.sidebar)
            }
        }
        .task { nodes = doc.service.outline() }
    }
}

private extension PDFOutlineNode {
    var childrenOrNil: [PDFOutlineNode]? { children.isEmpty ? nil : children }
}
