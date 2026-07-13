import SwiftUI
import RCodexPDFCore

@main
struct RCodexPDFApp: App {
    @StateObject private var appState = AppState()
    @ObservedObject private var settingsHolder = SettingsHolder.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(colorScheme(for: appState.settings.appearanceMode))
                .dynamicTypeSize(dynamicTypeSize(for: settingsHolder.uiFontSizePreset))
                .onOpenURL { url in
                    appState.open(url: url)
                }
                .onAppear {
                    appState.handleLaunchArguments()
                }
        }
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") { appState.selectedSection = .settings }
                    .keyboardShortcut(",", modifiers: .command)
            }
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    Task { await appState.updateViewModel.checkManually() }
                }
            }
            CommandGroup(replacing: .newItem) {
                Button("Open PDF…") { appState.presentOpenPDFPanel() }
                    .keyboardShortcut("o", modifiers: .command)
                Button("Open Code File…") { appState.presentOpenCodeFilePanel() }
                    .keyboardShortcut("o", modifiers: [.command, .shift])
                Button("New Chat") { appState.newChat() }
                    .keyboardShortcut("n", modifiers: [.command, .shift])
            }
            CommandGroup(after: .toolbar) {
                Button("Find in PDF") { appState.activePDF?.isSearchVisible.toggle() }
                    .keyboardShortcut("f", modifiers: .command)
                Button("Zoom In") { appState.activePDF?.zoomIn() }
                    .keyboardShortcut("=", modifiers: .command)
                Button("Zoom Out") { appState.activePDF?.zoomOut() }
                    .keyboardShortcut("-", modifiers: .command)
                Button("Rotate Page") { appState.activePDF?.rotate() }
                    .keyboardShortcut("r", modifiers: [.command, .shift])
                Divider()
                Button("Run") { appState.activeCodeFile?.run() }
                    .keyboardShortcut(.return, modifiers: .command)
                Button("Stop") { appState.activeCodeFile?.stop() }
                    .keyboardShortcut(".", modifiers: .command)
            }
        }
    }

    private func colorScheme(for mode: AppearanceMode) -> ColorScheme? {
        switch mode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    private func dynamicTypeSize(for preset: UIFontSizePreset) -> DynamicTypeSize {
        switch preset {
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .extraLarge: return .xLarge
        }
    }
}
