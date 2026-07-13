import Foundation
import AppKit
import PDFKit
import RCodexPDFCore

@MainActor
final class OpenPDFDocument: ObservableObject, Identifiable {
    let id = UUID()
    let url: URL
    let service: PDFService
    let pdfView = PDFView()

    @Published var title: String
    @Published var currentPageIndex: Int = 0
    @Published var zoomFactor: CGFloat = 1.0
    @Published var isSearchVisible = false
    @Published var searchQuery = ""
    @Published var searchResults: [PDFSearchResult] = []
    @Published var currentSearchIndex = 0
    @Published var sidebarMode: PDFSidebarMode = .none
    @Published var isPasswordPromptVisible = false

    private let settings: AppSettings

    enum PDFSidebarMode {
        case none, thumbnails, outline
    }

    init?(url: URL, settings: AppSettings) {
        guard let service = try? PDFService(url: url) else { return nil }
        self.url = url
        self.service = service
        self.title = url.lastPathComponent
        self.settings = settings

        pdfView.document = service.document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical

        if service.document.isLocked {
            isPasswordPromptVisible = true
        } else if settings.pdfRememberLastPage, let lastPage = settings.lastPage(forPDF: url),
                  let page = service.document.page(at: lastPage) {
            pdfView.go(to: page)
            currentPageIndex = lastPage
        }
    }

    func unlock(password: String) -> Bool {
        let success = service.unlock(password: password)
        if success {
            isPasswordPromptVisible = false
            pdfView.document = service.document
        }
        return success
    }

    func zoomIn() { pdfView.zoomIn(nil) }
    func zoomOut() { pdfView.zoomOut(nil) }
    func rotate() {
        guard let page = pdfView.currentPage else { return }
        page.rotation = (page.rotation + 90) % 360
    }

    func goToPage(_ index: Int) {
        guard let page = service.document.page(at: index) else { return }
        pdfView.go(to: page)
        currentPageIndex = index
        persistLastPage()
    }

    func persistLastPage() {
        guard settings.pdfRememberLastPage else { return }
        settings.setLastPage(currentPageIndex, forPDF: url)
    }

    func performSearch() {
        searchResults = service.search(searchQuery)
        currentSearchIndex = 0
        pdfView.document?.cancelFindString()
        pdfView.highlightedSelections = nil
        if !searchResults.isEmpty {
            jumpToSearchResult(index: 0)
        }
        // Also drive PDFKit's native incremental find for selection highlighting across the doc.
        if !searchQuery.isEmpty {
            pdfView.document?.beginFindString(searchQuery, withOptions: .caseInsensitive)
        }
    }

    func jumpToSearchResult(index: Int) {
        guard searchResults.indices.contains(index) else { return }
        currentSearchIndex = index
        let result = searchResults[index]
        goToPage(result.pageIndex)
    }

    func nextSearchResult() {
        guard !searchResults.isEmpty else { return }
        jumpToSearchResult(index: (currentSearchIndex + 1) % searchResults.count)
    }

    func previousSearchResult() {
        guard !searchResults.isEmpty else { return }
        jumpToSearchResult(index: (currentSearchIndex - 1 + searchResults.count) % searchResults.count)
    }

    func copySelectedText() {
        guard let selection = pdfView.currentSelection, let text = selection.string else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    func print() {
        let operation = service.document.printOperation(
            for: NSPrintInfo.shared,
            scalingMode: .pageScaleDownToFit,
            autoRotate: true
        )
        operation?.run()
    }
}
