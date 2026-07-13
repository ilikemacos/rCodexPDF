import Foundation

/// Resolves and creates rCodexPDF's on-disk storage locations under
/// `~/Library/Application Support/rCodexPDF/`.
public enum ApplicationSupport {
    public static var rootDirectory: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("rCodexPDF", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    public static var chatHistoryDirectory: URL = {
        let dir = rootDirectory.appendingPathComponent("ChatHistory", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    public static var configFile: URL = {
        rootDirectory.appendingPathComponent("config.json")
    }()
}

/// Generic JSON file store used by chat history, config, and other persisted models.
public enum JSONFileStore {
    public static func load<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(T.self, from: data)
    }

    public static func save<T: Encodable>(_ value: T, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        try data.write(to: url, options: .atomic)
    }
}
