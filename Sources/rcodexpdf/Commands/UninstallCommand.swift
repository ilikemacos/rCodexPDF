import ArgumentParser
import Foundation
import RCodexPDFCore

struct UninstallCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "uninstall",
        abstract: "Remove rCodexPDF, its CLI, and (optionally) its data and stored API keys."
    )

    @Flag(name: .long, help: "Also remove chat history, settings, and stored API keys.")
    var purge = false

    @Flag(name: .long, help: "Skip the confirmation prompt.")
    var yes = false

    func run() throws {
        if !yes {
            print("This will remove /Applications/rCodexPDF.app and the rcodexpdf CLI. Continue? [y/N] ", terminator: "")
            guard let answer = readLine(), answer.lowercased().hasPrefix("y") else {
                CLIOutput.info("Cancelled.")
                return
            }
        }

        let fm = FileManager.default
        var removed: [String] = []

        let appPath = "/Applications/rCodexPDF.app"
        if fm.fileExists(atPath: appPath) {
            try? fm.removeItem(atPath: appPath)
            removed.append(appPath)
        }

        for cliPath in ["/usr/local/bin/rcodexpdf", (fm.homeDirectoryForCurrentUser.appendingPathComponent(".local/bin/rcodexpdf")).path] {
            if fm.fileExists(atPath: cliPath) {
                try? fm.removeItem(atPath: cliPath)
                removed.append(cliPath)
            }
        }

        let completionPaths = [
            "/usr/local/share/zsh/site-functions/_rcodexpdf",
            "/usr/local/etc/bash_completion.d/rcodexpdf",
            fm.homeDirectoryForCurrentUser.appendingPathComponent(".zsh/completions/_rcodexpdf").path
        ]
        for path in completionPaths where fm.fileExists(atPath: path) {
            try? fm.removeItem(atPath: path)
            removed.append(path)
        }

        if purge {
            let dataDir = ApplicationSupport.rootDirectory
            if fm.fileExists(atPath: dataDir.path) {
                try? fm.removeItem(at: dataDir)
                removed.append(dataDir.path)
            }
            let keychain = KeychainStore()
            for provider in AIProviderRegistry.all {
                keychain.deleteAPIKey(for: provider.id)
            }
            CLIOutput.info("Removed stored data and API keys.")
        } else {
            CLIOutput.info("Kept application data and API keys. Re-run with --purge to remove everything.")
        }

        if removed.isEmpty {
            CLIOutput.warn("Nothing found to remove. rCodexPDF may already be uninstalled.")
        } else {
            for path in removed { CLIOutput.success("Removed \(path)") }
        }
    }
}
