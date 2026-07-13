import ArgumentParser
import Foundation
import RCodexPDFCore

struct OpenCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "open",
        abstract: "Open a PDF or code file in the rCodexPDF app."
    )

    @Argument(help: "Path to a .pdf or source code file.")
    var path: String

    func run() throws {
        let url = URL(fileURLWithPath: path).standardizedFileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            CLIOutput.fail("File not found: \(path)")
            throw ExitCode.failure
        }
        if AppLauncher.openInApp(fileURL: url) {
            CLIOutput.success("Opened \(url.lastPathComponent).")
        } else {
            CLIOutput.fail("Could not launch rCodexPDF.app.")
            throw ExitCode.failure
        }
    }
}
