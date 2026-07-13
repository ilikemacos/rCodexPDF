import ArgumentParser
import Foundation
import RCodexPDFCore

struct ConfigCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "config",
        abstract: "View or change rCodexPDF configuration.",
        subcommands: [ConfigList.self, ConfigGet.self, ConfigSet.self, ConfigPath.self, ConfigSetKey.self, ConfigRemoveKey.self],
        defaultSubcommand: ConfigList.self
    )
}

private let knownKeys = [
    "appearance", "editor-theme", "editor-font-size", "auto-save",
    "default-provider", "pdf-remember-last-page", "cli-color"
]

struct ConfigList: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "list", abstract: "List all configuration values.")

    func run() throws {
        let s = AppSettings.shared
        print(ANSI.bold("appearance") + " = \(s.appearanceMode.rawValue)")
        print(ANSI.bold("editor-theme") + " = \(s.editorTheme.rawValue)")
        print(ANSI.bold("editor-font-size") + " = \(Int(s.editorFontSize))")
        print(ANSI.bold("auto-save") + " = \(s.autoSaveEnabled)")
        print(ANSI.bold("default-provider") + " = \(s.defaultAIProvider)")
        print(ANSI.bold("pdf-remember-last-page") + " = \(s.pdfRememberLastPage)")
        print(ANSI.bold("cli-color") + " = \(s.cliColorOutput)")
        print("")
        print(ANSI.dim("Providers with an API key stored in Keychain:"))
        let keychain = KeychainStore()
        for provider in AIProviderRegistry.all {
            let mark = keychain.hasAPIKey(for: provider.id) ? ANSI.green("✔") : ANSI.dim("—")
            print("  \(mark) \(provider.id)")
        }
    }
}

struct ConfigGet: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "get", abstract: "Print a single configuration value.")
    @Argument(help: "One of: \(knownKeys.joined(separator: ", "))")
    var key: String

    func run() throws {
        let s = AppSettings.shared
        switch key {
        case "appearance": print(s.appearanceMode.rawValue)
        case "editor-theme": print(s.editorTheme.rawValue)
        case "editor-font-size": print(Int(s.editorFontSize))
        case "auto-save": print(s.autoSaveEnabled)
        case "default-provider": print(s.defaultAIProvider)
        case "pdf-remember-last-page": print(s.pdfRememberLastPage)
        case "cli-color": print(s.cliColorOutput)
        default:
            CLIOutput.fail("Unknown key '\(key)'. Known keys: \(knownKeys.joined(separator: ", "))")
            throw ExitCode.failure
        }
    }
}

struct ConfigSet: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "set", abstract: "Set a configuration value.")
    @Argument(help: "One of: \(knownKeys.joined(separator: ", "))")
    var key: String
    @Argument(help: "New value.")
    var value: String

    func run() throws {
        let s = AppSettings.shared
        switch key {
        case "appearance":
            guard let mode = AppearanceMode(rawValue: value) else { throw ValidationError("Expected one of: system, light, dark") }
            s.appearanceMode = mode
        case "editor-theme":
            guard let theme = EditorTheme(rawValue: value) else { throw ValidationError("Expected one of: \(EditorTheme.allCases.map(\.rawValue).joined(separator: ", "))") }
            s.editorTheme = theme
        case "editor-font-size":
            guard let size = Double(value) else { throw ValidationError("Expected a number") }
            s.editorFontSize = size
        case "auto-save":
            guard let flag = Bool(value) else { throw ValidationError("Expected true or false") }
            s.autoSaveEnabled = flag
        case "default-provider":
            guard AIProviderRegistry.provider(withID: value) != nil else {
                throw ValidationError("Unknown provider. Available: \(AIProviderRegistry.all.map(\.id).joined(separator: ", "))")
            }
            s.defaultAIProvider = value
        case "pdf-remember-last-page":
            guard let flag = Bool(value) else { throw ValidationError("Expected true or false") }
            s.pdfRememberLastPage = flag
        case "cli-color":
            guard let flag = Bool(value) else { throw ValidationError("Expected true or false") }
            s.cliColorOutput = flag
        default:
            CLIOutput.fail("Unknown key '\(key)'. Known keys: \(knownKeys.joined(separator: ", "))")
            throw ExitCode.failure
        }
        CLIOutput.success("Set \(key) = \(value)")
    }
}

struct ConfigPath: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "path", abstract: "Print the config/data directory path.")
    func run() throws {
        print(ApplicationSupport.rootDirectory.path)
    }
}

struct ConfigSetKey: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "set-key", abstract: "Securely store an API key for a provider in the macOS Keychain.")
    @Argument(help: "Provider id: \(AIProviderRegistry.all.map(\.id).joined(separator: ", "))")
    var provider: String

    func run() throws {
        guard AIProviderRegistry.provider(withID: provider) != nil else {
            CLIOutput.fail("Unknown provider '\(provider)'. Available: \(AIProviderRegistry.all.map(\.id).joined(separator: ", "))")
            throw ExitCode.failure
        }
        let key = SecureInput.readSecret(prompt: "API key for \(provider) (input hidden): ")
        guard !key.isEmpty else {
            CLIOutput.fail("Empty key, not saved.")
            throw ExitCode.failure
        }
        try KeychainStore().setAPIKey(key, for: provider)
        CLIOutput.success("Saved API key for \(provider) to Keychain.")
    }
}

struct ConfigRemoveKey: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "remove-key", abstract: "Remove a stored API key.")
    @Argument var provider: String

    func run() throws {
        if KeychainStore().deleteAPIKey(for: provider) {
            CLIOutput.success("Removed API key for \(provider).")
        } else {
            CLIOutput.fail("No key found for \(provider).")
            throw ExitCode.failure
        }
    }
}
