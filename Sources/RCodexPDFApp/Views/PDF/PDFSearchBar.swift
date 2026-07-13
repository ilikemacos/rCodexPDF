import SwiftUI

struct PDFSearchBar: View {
    @ObservedObject var doc: OpenPDFDocument
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Find in document", text: $doc.searchQuery)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit { doc.performSearch() }
                .onChange(of: doc.searchQuery) { _ in doc.performSearch() }

            if !doc.searchResults.isEmpty {
                Text("\(doc.currentSearchIndex + 1) of \(doc.searchResults.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if !doc.searchQuery.isEmpty {
                Text("No results").font(.caption).foregroundStyle(.secondary)
            }

            Button { doc.previousSearchResult() } label: { Image(systemName: "chevron.up") }
                .buttonStyle(.plain)
                .disabled(doc.searchResults.isEmpty)
            Button { doc.nextSearchResult() } label: { Image(systemName: "chevron.down") }
                .buttonStyle(.plain)
                .disabled(doc.searchResults.isEmpty)
            Button { doc.isSearchVisible = false } label: { Image(systemName: "xmark.circle.fill") }
                .buttonStyle(.plain)
        }
        .padding(8)
        .background(.bar)
        .onAppear { isFocused = true }
    }
}
