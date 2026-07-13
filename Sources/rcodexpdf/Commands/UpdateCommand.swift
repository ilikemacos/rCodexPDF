import ArgumentParser
import Foundation
import RCodexPDFCore

private struct GitHubRelease: Decodable {
    let tagName: String
    let htmlURL: String
    let body: String?

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case body
    }
}

struct UpdateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Check for and install the latest rCodexPDF release."
    )

    @Flag(name: .long, help: "Check for updates without installing.")
    var checkOnly = false

    @Flag(name: .long, help: "Skip the confirmation prompt and install immediately.")
    var yes = false

    static let releasesAPIURL = URL(string: "https://api.github.com/repos/ilikemacos/rCodexPDF/releases/latest")!
    static let installScriptURL = "https://raw.githubusercontent.com/ilikemacos/rCodexPDF/main/install.sh"

    func run() async throws {
        CLIOutput.info("Checking for updates… (current version \(RCodexPDFVersion.current))")

        let release: GitHubRelease
        do {
            var request = URLRequest(url: Self.releasesAPIURL)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                CLIOutput.fail("Could not reach GitHub releases API.")
                throw ExitCode.failure
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .useDefaultKeys
            release = try decoder.decode(GitHubRelease.self, from: data)
        } catch {
            CLIOutput.fail("Update check failed: \(error.localizedDescription)")
            throw ExitCode.failure
        }

        let latestVersion = release.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
        if !isNewer(latestVersion, than: RCodexPDFVersion.current) {
            CLIOutput.success("You're already on the latest version (\(RCodexPDFVersion.current)).")
            return
        }

        CLIOutput.info("A new version is available: \(ANSI.bold(latestVersion)) (you have \(RCodexPDFVersion.current))")
        print(release.htmlURL)

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
        process.arguments = ["-c", "curl -fsSL \(Self.installScriptURL) | bash"]
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus == 0 {
            CLIOutput.success("Update complete.")
        } else {
            CLIOutput.fail("Installer exited with status \(process.terminationStatus).")
            throw ExitCode(process.terminationStatus)
        }
    }

    /// Simple dotted-integer semver comparison (`1.2.10` > `1.2.9`), good enough for our tag scheme.
    private func isNewer(_ candidate: String, than current: String) -> Bool {
        let c = candidate.split(separator: ".").compactMap { Int($0) }
        let cur = current.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(c.count, cur.count) {
            let a = i < c.count ? c[i] : 0
            let b = i < cur.count ? cur[i] : 0
            if a != b { return a > b }
        }
        return false
    }
}
