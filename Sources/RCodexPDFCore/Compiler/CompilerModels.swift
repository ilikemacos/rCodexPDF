import Foundation

public enum BuildEvent: Sendable {
    case stdout(String)
    case stderr(String)
    case diagnostic(CompilerDiagnostic)
    case stepStarted(String)
    case processExited(step: String, code: Int32)
    case finished(success: Bool)
}

public enum DiagnosticSeverity: String, Sendable {
    case error
    case warning
    case note
}

public struct CompilerDiagnostic: Sendable, Identifiable {
    public let id = UUID()
    public let file: String
    public let line: Int
    public let column: Int?
    public let severity: DiagnosticSeverity
    public let message: String
    public let rawLine: String
}

public enum CompilerError: Error, LocalizedError, Sendable {
    case toolchainNotFound(tool: String, language: String)
    case unsupportedLanguage(String)
    case luaNotSupported

    public var errorDescription: String? {
        switch self {
        case .toolchainNotFound(let tool, let language):
            return "'\(tool)' was not found on PATH. Install a \(language) toolchain to compile/run \(language) files."
        case .unsupportedLanguage(let ext):
            return "No compiler/runner is registered for file extension '.\(ext)'."
        case .luaNotSupported:
            return "Lua is intentionally not supported by rCodexPDF."
        }
    }
}

/// A single process invocation (either a compile step or a run step).
public struct BuildStep: Sendable {
    public let label: String
    public let executable: String
    public let arguments: [String]
    public let workingDirectory: URL

    public init(label: String, executable: String, arguments: [String], workingDirectory: URL) {
        self.label = label
        self.executable = executable
        self.arguments = arguments
        self.workingDirectory = workingDirectory
    }
}

/// Parses common `file:line:col: severity: message` compiler diagnostic formats
/// (clang/gcc, rustc, go vet, swiftc, javac, kotlinc, tsc, csc) out of stderr text.
public enum DiagnosticParser {
    private static let patterns: [NSRegularExpression] = [
        // clang/gcc/rustc/swiftc/go: path:line:col: severity: message
        try! NSRegularExpression(pattern: #"^(.+?):(\d+):(\d+):\s*(error|warning|note):\s*(.+)$"#),
        // javac: path:line: error: message  (no column)
        try! NSRegularExpression(pattern: #"^(.+?):(\d+):\s*(error|warning):\s*(.+)$"#),
        // tsc/csc: path(line,col): error TS1234: message
        try! NSRegularExpression(pattern: #"^(.+?)\((\d+),(\d+)\):\s*(error|warning)\s+\w*\d*:\s*(.+)$"#)
    ]

    public static func parse(_ line: String) -> CompilerDiagnostic? {
        let range = NSRange(line.startIndex..., in: line)
        for (index, regex) in patterns.enumerated() {
            guard let match = regex.firstMatch(in: line, range: range) else { continue }
            func group(_ i: Int) -> String? {
                guard let r = Range(match.range(at: i), in: line) else { return nil }
                return String(line[r])
            }
            if index == 1 {
                guard let file = group(1), let lineStr = group(2),
                      let sevStr = group(3), let message = group(4) else { continue }
                return CompilerDiagnostic(
                    file: file, line: Int(lineStr) ?? 0, column: nil,
                    severity: DiagnosticSeverity(rawValue: sevStr) ?? .error,
                    message: message, rawLine: line
                )
            } else {
                guard let file = group(1), let lineStr = group(2), let colStr = group(3),
                      let sevStr = group(4), let message = group(5) else { continue }
                return CompilerDiagnostic(
                    file: file, line: Int(lineStr) ?? 0, column: Int(colStr),
                    severity: DiagnosticSeverity(rawValue: sevStr) ?? .error,
                    message: message, rawLine: line
                )
            }
        }
        return nil
    }
}
