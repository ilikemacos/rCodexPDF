import XCTest
@testable import RCodexPDFCore

final class LocalizationTests: XCTestCase {
    func testKnownKeyTranslatesInEveryLanguage() {
        for language in AppLanguage.allCases {
            let value = Localization.string("settings.title", language: language)
            XCTAssertFalse(value.isEmpty)
            XCTAssertNotEqual(value, "settings.title", "Missing \(language) translation for settings.title")
        }
    }

    func testUnknownKeyFallsBackToKeyItself() {
        XCTAssertEqual(Localization.string("does.not.exist", language: .en), "does.not.exist")
    }

    func testEnglishAndSpanishDiffer() {
        let en = Localization.string("sidebar.settings", language: .en)
        let es = Localization.string("sidebar.settings", language: .es)
        XCTAssertNotEqual(en, es)
    }

    func testAppSettingsLanguageDefaultsToEnglishAndPersists() {
        let suiteName = "com.rcodexpdf.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let settings = AppSettings(defaults: defaults)

        XCTAssertEqual(settings.language, .en)
        settings.language = .fr
        XCTAssertEqual(settings.language, .fr)
        XCTAssertEqual(settings.tr("sidebar.chat"), Localization.string("sidebar.chat", language: .fr))
    }

    func testUIFontSizePresetDefaultsToMedium() {
        let suiteName = "com.rcodexpdf.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let settings = AppSettings(defaults: defaults)

        XCTAssertEqual(settings.uiFontSizePreset, .medium)
        settings.uiFontSizePreset = .large
        XCTAssertEqual(settings.uiFontSizePreset, .large)
    }
}
