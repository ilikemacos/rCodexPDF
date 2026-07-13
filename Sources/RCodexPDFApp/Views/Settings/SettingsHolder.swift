import SwiftUI
import RCodexPDFCore

/// Bridges `AppSettings` (a plain class) into SwiftUI's `@Published`/binding world for the
/// in-window Settings tab.
@MainActor
final class SettingsHolder: ObservableObject {
    static let shared = SettingsHolder()
    private let settings = AppSettings.shared

    @Published var appearanceMode: AppearanceMode {
        didSet { settings.appearanceMode = appearanceMode }
    }
    @Published var editorTheme: EditorTheme {
        didSet { settings.editorTheme = editorTheme }
    }
    @Published var editorFontSize: Double {
        didSet { settings.editorFontSize = editorFontSize }
    }
    @Published var autoSaveEnabled: Bool {
        didSet { settings.autoSaveEnabled = autoSaveEnabled }
    }
    @Published var pdfRememberLastPage: Bool {
        didSet { settings.pdfRememberLastPage = pdfRememberLastPage }
    }
    @Published var cliColorOutput: Bool {
        didSet { settings.cliColorOutput = cliColorOutput }
    }
    @Published var autoCheckForUpdates: Bool {
        didSet { settings.autoCheckForUpdates = autoCheckForUpdates }
    }
    @Published var language: AppLanguage {
        didSet { settings.language = language }
    }
    @Published var uiFontSizePreset: UIFontSizePreset {
        didSet { settings.uiFontSizePreset = uiFontSizePreset }
    }

    func tr(_ key: String) -> String {
        Localization.string(key, language: language)
    }

    private init() {
        appearanceMode = settings.appearanceMode
        editorTheme = settings.editorTheme
        editorFontSize = settings.editorFontSize
        autoSaveEnabled = settings.autoSaveEnabled
        pdfRememberLastPage = settings.pdfRememberLastPage
        cliColorOutput = settings.cliColorOutput
        autoCheckForUpdates = settings.autoCheckForUpdates
        language = settings.language
        uiFontSizePreset = settings.uiFontSizePreset
    }
}
