import Foundation

enum AppLauncher {
    /// Launches the installed rCodexPDF.app, optionally handing it a file to open, via `open(1)`
    /// so the CLI stays a lightweight Foundation-only binary with no AppKit dependency.
    @discardableResult
    static func openInApp(fileURL: URL? = nil) -> Bool {
        var arguments = ["-a", "rCodexPDF"]
        if let fileURL {
            arguments.append(fileURL.path)
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = arguments
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}
