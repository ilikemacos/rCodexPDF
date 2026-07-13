import XCTest
@testable import RCodexPDFCore

final class UpdateCheckerTests: XCTestCase {
    func testIsNewerBasicCases() {
        XCTAssertTrue(UpdateChecker.isNewer("1.0.1", than: "1.0.0"))
        XCTAssertTrue(UpdateChecker.isNewer("1.1.0", than: "1.0.9"))
        XCTAssertTrue(UpdateChecker.isNewer("2.0.0", than: "1.9.9"))
        XCTAssertFalse(UpdateChecker.isNewer("1.0.0", than: "1.0.0"))
        XCTAssertFalse(UpdateChecker.isNewer("1.0.0", than: "1.0.1"))
    }

    func testIsNewerHandlesDoubleDigitComponents() {
        // Naive string comparison would get "1.2.10" > "1.2.9" wrong; integer comparison must not.
        XCTAssertTrue(UpdateChecker.isNewer("1.2.10", than: "1.2.9"))
        XCTAssertFalse(UpdateChecker.isNewer("1.2.9", than: "1.2.10"))
    }

    func testIsNewerHandlesDifferentComponentCounts() {
        XCTAssertTrue(UpdateChecker.isNewer("1.1", than: "1.0.9"))
        XCTAssertFalse(UpdateChecker.isNewer("1.0", than: "1.0.0"))
    }

    func testReleaseVersionStripsLeadingV() {
        let release = GitHubReleaseInfo(
            tagName: "v1.2.3",
            htmlURL: URL(string: "https://example.com")!,
            body: nil,
            assets: []
        )
        XCTAssertEqual(release.version, "1.2.3")
    }

    func testMacOSZipAssetDetection() {
        let matching = ReleaseAsset(name: "rCodexPDF-1.2.3-macOS.zip", browserDownloadURL: URL(string: "https://example.com/a")!)
        let other = ReleaseAsset(name: "rCodexPDF-1.2.3.pkg", browserDownloadURL: URL(string: "https://example.com/b")!)
        let release = GitHubReleaseInfo(
            tagName: "v1.2.3",
            htmlURL: URL(string: "https://example.com")!,
            body: nil,
            assets: [other, matching]
        )
        XCTAssertEqual(release.macOSZipAsset?.name, "rCodexPDF-1.2.3-macOS.zip")
    }

    func testNoMacOSZipAssetReturnsNil() {
        let pkgOnly = ReleaseAsset(name: "rCodexPDF-1.2.3.pkg", browserDownloadURL: URL(string: "https://example.com/b")!)
        let release = GitHubReleaseInfo(
            tagName: "v1.2.3",
            htmlURL: URL(string: "https://example.com")!,
            body: nil,
            assets: [pkgOnly]
        )
        XCTAssertNil(release.macOSZipAsset)
    }
}
