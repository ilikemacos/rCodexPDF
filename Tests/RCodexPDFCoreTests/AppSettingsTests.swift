import XCTest
@testable import RCodexPDFCore

final class AppSettingsTests: XCTestCase {
    private func makeIsolatedSettings() -> AppSettings {
        let suiteName = "com.rcodexpdf.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return AppSettings(defaults: defaults)
    }

    func testDefaults() {
        let settings = makeIsolatedSettings()
        XCTAssertEqual(settings.appearanceMode, .system)
        XCTAssertEqual(settings.editorTheme, .system)
        XCTAssertEqual(settings.editorFontSize, 13.0)
        XCTAssertTrue(settings.autoSaveEnabled)
        XCTAssertTrue(settings.pdfRememberLastPage)
        XCTAssertTrue(settings.cliColorOutput)
        XCTAssertEqual(settings.defaultAIProvider, "claude")
    }

    func testRoundTripAppearance() {
        let settings = makeIsolatedSettings()
        settings.appearanceMode = .dark
        XCTAssertEqual(settings.appearanceMode, .dark)
    }

    func testRecentPDFsOrderingAndDedup() {
        let settings = makeIsolatedSettings()
        let tempDir = FileManager.default.temporaryDirectory
        let a = tempDir.appendingPathComponent("a-\(UUID().uuidString).pdf")
        let b = tempDir.appendingPathComponent("b-\(UUID().uuidString).pdf")
        FileManager.default.createFile(atPath: a.path, contents: Data())
        FileManager.default.createFile(atPath: b.path, contents: Data())
        defer {
            try? FileManager.default.removeItem(at: a)
            try? FileManager.default.removeItem(at: b)
        }

        settings.addRecentPDF(a)
        settings.addRecentPDF(b)
        settings.addRecentPDF(a) // re-adding should move it to the front, not duplicate

        let recents = settings.recentPDFs()
        XCTAssertEqual(recents.first, a)
        XCTAssertEqual(recents.count, 2)
    }

    func testLastPagePersistence() {
        let settings = makeIsolatedSettings()
        let url = URL(fileURLWithPath: "/tmp/does-not-need-to-exist.pdf")
        XCTAssertNil(settings.lastPage(forPDF: url))
        settings.setLastPage(4, forPDF: url)
        XCTAssertEqual(settings.lastPage(forPDF: url), 4)
    }

    func testProviderBaseURLOverride() {
        let settings = makeIsolatedSettings()
        XCTAssertNil(settings.baseURLOverride(forProvider: "llama"))
        let url = URL(string: "https://example.com/v1")!
        settings.setBaseURLOverride(url, forProvider: "llama")
        XCTAssertEqual(settings.baseURLOverride(forProvider: "llama"), url)
        settings.setBaseURLOverride(nil, forProvider: "llama")
        XCTAssertNil(settings.baseURLOverride(forProvider: "llama"))
    }
}
