import Foundation
import RCodexPDFCore

/// Minimal ANSI color helper. Honors `AppSettings.cliColorOutput` and disables color when stdout
/// isn't a TTY (e.g. piped into a file or another program) or `NO_COLOR` is set, matching
/// conventional CLI behavior.
enum ANSI {
    static var enabled: Bool = {
        if ProcessInfo.processInfo.environment["NO_COLOR"] != nil { return false }
        guard AppSettings.shared.cliColorOutput else { return false }
        return isatty(fileno(stdout)) != 0
    }()

    static func wrap(_ text: String, _ code: String) -> String {
        enabled ? "\u{001B}[\(code)m\(text)\u{001B}[0m" : text
    }

    static func red(_ text: String) -> String { wrap(text, "31") }
    static func green(_ text: String) -> String { wrap(text, "32") }
    static func yellow(_ text: String) -> String { wrap(text, "33") }
    static func blue(_ text: String) -> String { wrap(text, "34") }
    static func magenta(_ text: String) -> String { wrap(text, "35") }
    static func cyan(_ text: String) -> String { wrap(text, "36") }
    static func bold(_ text: String) -> String { wrap(text, "1") }
    static func dim(_ text: String) -> String { wrap(text, "2") }
}

enum CLIOutput {
    static func info(_ message: String) { print(ANSI.cyan("ℹ") + " " + message) }
    static func success(_ message: String) { print(ANSI.green("✔") + " " + message) }
    static func warn(_ message: String) { print(ANSI.yellow("⚠") + " " + message) }
    static func fail(_ message: String) { FileHandle.standardError.write((ANSI.red("✖") + " " + message + "\n").data(using: .utf8)!) }
}
