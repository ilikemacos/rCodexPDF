import Foundation

/// Locates compiler/interpreter executables on the user's `PATH`, plus common Homebrew
/// locations that may not be on `PATH` inside an app bundle's restricted environment.
public enum ToolchainLocator {
    private static let extraSearchPaths = [
        "/opt/homebrew/bin",
        "/usr/local/bin",
        "/usr/bin",
        "/bin",
        "/opt/homebrew/opt/openjdk/bin"
    ]

    public static func find(_ executable: String) -> String? {
        let fileManager = FileManager.default
        let pathEnv = ProcessInfo.processInfo.environment["PATH"] ?? ""
        let searchPaths = pathEnv.split(separator: ":").map(String.init) + extraSearchPaths

        var seen = Set<String>()
        for dir in searchPaths {
            guard !seen.contains(dir) else { continue }
            seen.insert(dir)
            let candidate = (dir as NSString).appendingPathComponent(executable)
            if fileManager.isExecutableFile(atPath: candidate) {
                return candidate
            }
        }
        return nil
    }

    public static func isAvailable(_ executable: String) -> Bool {
        find(executable) != nil
    }
}
