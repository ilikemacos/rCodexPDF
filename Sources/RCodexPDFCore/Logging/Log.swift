import Foundation
import os

/// Centralized logging facility for rCodexPDF, backed by the unified logging system (os.Logger).
public enum LogCategory: String {
    case app = "App"
    case pdf = "PDF"
    case editor = "Editor"
    case compiler = "Compiler"
    case ai = "AI"
    case cli = "CLI"
    case network = "Network"
    case storage = "Storage"
}

public struct Log {
    private static let subsystem = "com.rcodexpdf.app"
    private static var loggers: [LogCategory: Logger] = [:]
    private static let lock = NSLock()

    private static func logger(for category: LogCategory) -> Logger {
        lock.lock()
        defer { lock.unlock() }
        if let existing = loggers[category] {
            return existing
        }
        let logger = Logger(subsystem: subsystem, category: category.rawValue)
        loggers[category] = logger
        return logger
    }

    public static func debug(_ message: String, category: LogCategory = .app) {
        logger(for: category).debug("\(message, privacy: .public)")
    }

    public static func info(_ message: String, category: LogCategory = .app) {
        logger(for: category).info("\(message, privacy: .public)")
    }

    public static func warning(_ message: String, category: LogCategory = .app) {
        logger(for: category).warning("\(message, privacy: .public)")
    }

    public static func error(_ message: String, category: LogCategory = .app) {
        logger(for: category).error("\(message, privacy: .public)")
    }

    /// Also mirrors messages to a rotating file log under ~/Library/Logs/rCodexPDF for `rcodexpdf` CLI diagnostics.
    public static func fileLogURL() -> URL {
        let dir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Logs/rCodexPDF", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("rcodexpdf.log")
    }

    public static func appendToFile(_ message: String, category: LogCategory = .app) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "[\(timestamp)] [\(category.rawValue)] \(message)\n"
        let url = fileLogURL()
        if let data = line.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: url.path) {
                if let handle = try? FileHandle(forWritingTo: url) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    try? handle.close()
                }
            } else {
                try? data.write(to: url)
            }
        }
    }
}
