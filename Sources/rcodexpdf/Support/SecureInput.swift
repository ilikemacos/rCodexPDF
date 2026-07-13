import Foundation
#if canImport(Glibc)
import Glibc
#else
import Darwin
#endif

/// Reads a line from stdin with terminal echo disabled, for API key entry, so the secret never
/// appears in shell history or on-screen.
enum SecureInput {
    static func readSecret(prompt: String) -> String {
        print(prompt, terminator: "")
        fflush(stdout)

        var originalTerm = termios()
        tcgetattr(STDIN_FILENO, &originalTerm)
        var rawTerm = originalTerm
        rawTerm.c_lflag &= ~tcflag_t(ECHO)
        tcsetattr(STDIN_FILENO, TCSANOW, &rawTerm)

        let line = readLine() ?? ""

        tcsetattr(STDIN_FILENO, TCSANOW, &originalTerm)
        print("")
        return line
    }
}
