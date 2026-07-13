import ArgumentParser
import Foundation
import RCodexPDFCore

@main
struct RCodexPDFCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "rcodexpdf",
        abstract: "rCodexPDF — PDF viewer, code editor/compiler, and AI chat assistant for macOS.",
        discussion: """
        Running \(ANSIHelp.bold("rcodexpdf")) with no arguments launches the rCodexPDF app.
        Run \(ANSIHelp.bold("rcodexpdf <command> --help")) for details on a specific command.
        """,
        version: RCodexPDFVersion.current,
        subcommands: [
            OpenCommand.self,
            PDFCommand.self,
            CompileCommand.self,
            ChatCommand.self,
            ConfigCommand.self,
            UpdateCommand.self,
            UninstallCommand.self
        ]
    )

    func run() async throws {
        Log.appendToFile("rcodexpdf launched with no subcommand", category: .cli)
        if AppLauncher.openInApp() {
            CLIOutput.success("Launched rCodexPDF.")
        } else {
            CLIOutput.fail("Could not launch rCodexPDF.app. Is it installed? Try `rcodexpdf update` or reinstall.")
            throw ExitCode.failure
        }
    }
}

enum ANSIHelp {
    static func bold(_ s: String) -> String { ANSI.bold(s) }
}
