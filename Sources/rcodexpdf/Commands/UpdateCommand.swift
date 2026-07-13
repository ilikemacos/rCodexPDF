import ArgumentParser
import Foundation
import RCodexPDFCore

struct UpdateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Check for and install the latest rCodexPDF release."
    )

    @Flag(name: .long, help: "Check for updates without installing.")
    var checkOnly = false

    @Flag(name: .long, help: "Skip the confirmation prompt and install immediately.")
    var yes = false

    func run() async throws {
        CLIOutput.info("Checking for updates… (current version \(RCodexPDFVersion.current))")

        let availability: UpdateAvailability
        do {
            availability = try await UpdateChecker.checkForUpdate()
        } catch {
            CLIOutput.fail("Update check failed: \(error.localizedDescription)")
            throw ExitCode.failure
        }

        guard case .updateAvailable(let release) = availability else {
            CLIOutput.success("You're already on the latest version (\(RCodexPDFVersion.current)).")
            return
        }

        CLIOutput.info("A new version is available: \(ANSI.bold(release.version)) (you have \(RCodexPDFVersion.current))")
        print(release.htmlURL.absoluteString)

        if checkOnly { return }

        if !yes {
            print("Install now via the official installer script? [y/N] ", terminator: "")
            guard let answer = readLine(), answer.lowercased().hasPrefix("y") else {
                CLIOutput.info("Skipped. Run `rcodexpdf update --yes` to install non-interactively.")
                return
            }
        }

        CLIOutput.info("Running installer…")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", "curl -fsSL \(UpdateChecker.installScriptURL) | bash"]
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus == 0 {
            CLIOutput.success("Update complete.")
        } else {
            CLIOutput.fail("Installer exited with status \(process.terminationStatus).")
            throw ExitCode(process.terminationStatus)
        }
    }
}
