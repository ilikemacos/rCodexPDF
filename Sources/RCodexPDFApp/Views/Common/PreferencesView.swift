import SwiftUI
import RCodexPDFCore

struct PreferencesView: View {
    var body: some View {
        TabView {
            GeneralPreferencesView()
                .tabItem { Label("General", systemImage: "gearshape") }
            EditorPreferencesView()
                .tabItem { Label("Editor", systemImage: "chevron.left.forwardslash.chevron.right") }
            ProviderSettingsView()
                .tabItem { Label("AI Providers", systemImage: "sparkles") }
        }
        .frame(width: 560, height: 420)
    }
}

struct GeneralPreferencesView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var settingsHolder = SettingsHolder.shared

    var body: some View {
        Form {
            Picker("Appearance", selection: $settingsHolder.appearanceMode) {
                ForEach(AppearanceMode.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
            }
            Toggle("Remember last opened PDF page", isOn: $settingsHolder.pdfRememberLastPage)
            Toggle("Colored CLI output", isOn: $settingsHolder.cliColorOutput)
            Toggle("Automatically check for updates", isOn: $settingsHolder.autoCheckForUpdates)
            Button("Check for Updates Now…") {
                Task { await appState.updateViewModel.checkManually() }
            }
        }
        .padding(20)
    }
}

struct EditorPreferencesView: View {
    @ObservedObject var settingsHolder = SettingsHolder.shared

    var body: some View {
        Form {
            Picker("Theme", selection: $settingsHolder.editorTheme) {
                ForEach(EditorTheme.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
            }
            Stepper(value: $settingsHolder.editorFontSize, in: 9...24, step: 1) {
                Text("Font size: \(Int(settingsHolder.editorFontSize))pt")
            }
            Toggle("Auto-save", isOn: $settingsHolder.autoSaveEnabled)
        }
        .padding(20)
    }
}

/// Bridges `AppSettings` (a plain class) into SwiftUI's `@Published`/binding world for the
/// Preferences window.
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

    private init() {
        appearanceMode = settings.appearanceMode
        editorTheme = settings.editorTheme
        editorFontSize = settings.editorFontSize
        autoSaveEnabled = settings.autoSaveEnabled
        pdfRememberLastPage = settings.pdfRememberLastPage
        cliColorOutput = settings.cliColorOutput
        autoCheckForUpdates = settings.autoCheckForUpdates
    }
}
