import ArgumentParser
import Foundation
import RCodexPDFCore

struct CompileCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "compile",
        abstract: "Compile and run a source file (C, C++, Rust, Go, Python, Java, JavaScript, TypeScript, Swift, Kotlin, C#, PHP, Ruby, Bash)."
    )

    @Argument(help: "Path to the source file.")
    var path: String

    func run() async throws {
        let url = URL(fileURLWithPath: path).standardizedFileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            CLIOutput.fail("File not found: \(path)")
            throw ExitCode.failure
        }
        guard let language = ProgrammingLanguage.detect(from: url) else {
            CLIOutput.fail("Unsupported file extension: .\(url.pathExtension)")
            throw ExitCode.failure
        }
        CLIOutput.info("Compiling \(url.lastPathComponent) as \(language.displayName)…")

        var exitCode: Int32 = 0
        do {
            for try await event in CompilerEngine.shared.run(file: url) {
                switch event {
                case .stepStarted(let label):
                    print(ANSI.dim("▶ \(label)…"))
                case .stdout(let line):
                    print(line)
                case .stderr(let line):
                    FileHandle.standardError.write((line + "\n").data(using: .utf8)!)
                case .diagnostic(let diagnostic):
                    let prefix = diagnostic.severity == .error ? ANSI.red("error") : ANSI.yellow("warning")
                    FileHandle.standardError.write("\(prefix): \((diagnostic.file as NSString).lastPathComponent):\(diagnostic.line): \(diagnostic.message)\n".data(using: .utf8)!)
                case .processExited(_, let code):
                    exitCode = code
                case .finished(let success):
                    if success {
                        CLIOutput.success("Finished.")
                    } else {
                        CLIOutput.fail("Build/run failed.")
                    }
                }
            }
        } catch {
            CLIOutput.fail(error.localizedDescription)
            throw ExitCode.failure
        }

        if exitCode != 0 {
            throw ExitCode(exitCode)
        }
    }
}
