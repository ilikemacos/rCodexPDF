import Foundation
import PDFKit
#if canImport(AppKit)
import AppKit
#endif

public struct PDFMetadata: Sendable {
    public let title: String?
    public let author: String?
    public let pageCount: Int
    public let isEncrypted: Bool
    public let isLocked: Bool
    public let fileSizeBytes: Int64
}

public enum PDFServiceError: Error, LocalizedError {
    case fileNotFound(String)
    case failedToLoad(String)
    case locked

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path): return "File not found: \(path)"
        case .failedToLoad(let path): return "Could not open PDF: \(path)"
        case .locked: return "This PDF is password protected."
        }
    }
}

/// Thin, testable wrapper around `PDFKit.PDFDocument` shared by the GUI viewer and the `rcodexpdf pdf` CLI command.
public final class PDFService {
    public let document: PDFDocument
    public let url: URL

    public init(url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw PDFServiceError.fileNotFound(url.path)
        }
        guard let doc = PDFDocument(url: url) else {
            throw PDFServiceError.failedToLoad(url.path)
        }
        self.document = doc
        self.url = url
    }

    public func unlock(password: String) -> Bool {
        document.unlock(withPassword: password)
    }

    public func metadata() -> PDFMetadata {
        let attributes = document.documentAttributes ?? [:]
        let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
        return PDFMetadata(
            title: attributes[PDFDocumentAttribute.titleAttribute] as? String,
            author: attributes[PDFDocumentAttribute.authorAttribute] as? String,
            pageCount: document.pageCount,
            isEncrypted: document.isEncrypted,
            isLocked: document.isLocked,
            fileSizeBytes: size
        )
    }

    public func outline() -> [PDFOutlineNode] {
        PDFOutlineNode.build(from: document.outlineRoot, document: document)
    }

    public func extractText(pageRange: Range<Int>? = nil) -> String {
        let range = pageRange ?? 0..<document.pageCount
        var text = ""
        for index in range where index >= 0 && index < document.pageCount {
            if let page = document.page(at: index), let pageText = page.string {
                text += pageText
                text += "\n\n"
            }
        }
        return text
    }

    public func search(_ query: String, caseSensitive: Bool = false) -> [PDFSearchResult] {
        guard !query.isEmpty else { return [] }
        let options: NSString.CompareOptions = caseSensitive ? [] : [.caseInsensitive]
        let selections = document.findString(query, withOptions: options)
        return selections.compactMap { selection -> PDFSearchResult? in
            guard let page = selection.pages.first else { return nil }
            let pageIndex = document.index(for: page)
            let bounds = selection.bounds(for: page)
            let snippet = selection.string ?? query
            return PDFSearchResult(pageIndex: pageIndex, snippet: snippet, boundsInPage: bounds)
        }
    }

    #if canImport(AppKit)
    public func thumbnail(forPage index: Int, size: CGSize) -> NSImage? {
        guard let page = document.page(at: index) else { return nil }
        return page.thumbnail(of: size, for: .mediaBox)
    }
    #endif
}
