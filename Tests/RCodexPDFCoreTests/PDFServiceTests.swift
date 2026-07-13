import XCTest
import CoreGraphics
import CoreText
import Foundation
import AppKit
@testable import RCodexPDFCore

final class PDFServiceTests: XCTestCase {
    /// Renders a minimal single-page PDF with a known text string, using Core Graphics directly
    /// (no external fixture files needed), so PDFService can be exercised against a real PDF.
    private func makeTestPDF(text: String) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).pdf")
        var mediaBox = CGRect(x: 0, y: 0, width: 200, height: 200)
        guard let context = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
            fatalError("Could not create PDF context")
        }
        context.beginPDFPage(nil)
        let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 18)]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributedString)
        context.textPosition = CGPoint(x: 20, y: 100)
        CTLineDraw(line, context)
        context.endPDFPage()
        context.closePDF()
        return url
    }

    func testLoadAndMetadata() throws {
        let url = makeTestPDF(text: "Hello rCodexPDF")
        defer { try? FileManager.default.removeItem(at: url) }

        let service = try PDFService(url: url)
        let metadata = service.metadata()
        XCTAssertEqual(metadata.pageCount, 1)
        XCTAssertFalse(metadata.isEncrypted)
        XCTAssertGreaterThan(metadata.fileSizeBytes, 0)
    }

    func testExtractText() throws {
        let url = makeTestPDF(text: "Hello rCodexPDF")
        defer { try? FileManager.default.removeItem(at: url) }

        let service = try PDFService(url: url)
        let text = service.extractText()
        XCTAssertTrue(text.contains("Hello rCodexPDF"))
    }

    func testSearchFindsKnownText() throws {
        let url = makeTestPDF(text: "FindThisPhrase")
        defer { try? FileManager.default.removeItem(at: url) }

        let service = try PDFService(url: url)
        let results = service.search("FindThisPhrase")
        XCTAssertFalse(results.isEmpty)
        XCTAssertEqual(results.first?.pageIndex, 0)
    }

    func testMissingFileThrows() {
        let url = URL(fileURLWithPath: "/tmp/does-not-exist-\(UUID().uuidString).pdf")
        XCTAssertThrowsError(try PDFService(url: url)) { error in
            guard case PDFServiceError.fileNotFound = error else {
                XCTFail("Expected fileNotFound, got \(error)")
                return
            }
        }
    }
}
