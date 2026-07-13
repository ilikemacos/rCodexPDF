import ArgumentParser
import Foundation
import RCodexPDFCore

@main
struct RCodexPDFCLI: AsyncParsableCommand {
    // NOTE: `discussion` (like the rest of `configuration`) is evaluated at static
    // type-initialization time, before ArgumentParser even parses arguments — so it must be a
    // plain constant with no I/O side effects. It used to call into ANSI/AppSettings (which
    // touches UserDefaults/cfprefsd), which could stall `rcodexpdf --help` on a machine where
    // that first preferences access is slow (observed hanging on a fresh CI runner).
    static let configuration = CommandConfiguration(
        commandName: "rcodexpdf",
        abstract: "rCodexPDF — PDF viewer, code editor/compiler, and AI chat assistant for macOS.",
        discussion: """
        Running "rcodexpdf" with no arguments launches the rCodexPDF app.
        Run "rcodexpdf <command> --help" for details on a specific command.
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
