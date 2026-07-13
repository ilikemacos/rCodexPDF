import Foundation

/// Formats source files by shelling out to each language's standard formatter, when installed.
/// If no formatter is found, `format` throws `CompilerError.toolchainNotFound` so the caller can
/// surface a clear message instead of silently doing nothing.
public enum CodeFormatter {
    private static func formatterCommand(for language: ProgrammingLanguage, file: URL) -> (tool: String, args: [String])? {
        switch language {
        case .c, .cpp:
            return ("clang-format", ["-i", file.path])
        case .go:
            return ("gofmt", ["-w", file.path])
        case .rust:
            return ("rustfmt", [file.path])
        case .javascript, .typescript, .php:
            return ("prettier", ["--write", file.path])
        case .python:
            return ("black", [file.path])
        case .swift:
            return ("swift-format", ["-i", file.path])
        case .ruby:
            return ("rubocop", ["-A", file.path])
        case .kotlin:
            return ("ktlint", ["-F", file.path])
        case .csharp:
            return ("dotnet-format", [file.path])
        case .java, .bash:
            return nil
        }
    }

    public static func format(file: URL, language: ProgrammingLanguage) throws {
        guard let command = formatterCommand(for: language, file: file) else {
            throw CompilerError.toolchainNotFound(tool: "formatter", language: language.displayName)
        }
        guard let toolPath = ToolchainLocator.find(command.tool) else {
            throw CompilerError.toolchainNotFound(tool: command.tool, language: language.displayName)
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: toolPath)
        process.arguments = command.args
        try process.run()
        process.waitUntilExit()
    }
}
