import Foundation

/// Editor color theme.
public enum EditorTheme: String, Codable, CaseIterable, Sendable {
    case system
    case light
    case dark
    case solarizedDark
    case monokai
}

/// Application-wide appearance mode.
public enum AppearanceMode: String, Codable, CaseIterable, Sendable {
    case system
    case light
    case dark
}

/// Persisted, user-configurable application settings.
/// Backed by `UserDefaults` (via an injectable suite) so both the GUI app and CLI share state,
/// and both can be unit tested with an isolated in-memory suite.
public final class AppSettings: @unchecked Sendable {
    public static let shared = AppSettings()

    private let defaults: UserDefaults
    private let lock = NSLock()

    public init(defaults: UserDefaults = UserDefaults(suiteName: "com.rcodexpdf.app") ?? .standard) {
        self.defaults = defaults
    }

    private enum Keys {
        static let appearanceMode = "appearanceMode"
        static let editorTheme = "editorTheme"
        static let editorFontSize = "editorFontSize"
        static let autoSaveEnabled = "autoSaveEnabled"
        static let defaultAIProvider = "defaultAIProvider"
        static let recentPDFs = "recentPDFs"
        static let recentFiles = "recentFiles"
        static let lastPageByDocument = "lastPageByDocument"
        static let pdfRememberLastPage = "pdfRememberLastPage"
        static let cliColorOutput = "cliColorOutput"
        static let telemetryOptIn = "telemetryOptIn"
        static let providerBaseURLOverrides = "providerBaseURLOverrides"
        static let providerModelSelection = "providerModelSelection"
    }

    public var appearanceMode: AppearanceMode {
        get {
            lock.lock(); defer { lock.unlock() }
            return AppearanceMode(rawValue: defaults.string(forKey: Keys.appearanceMode) ?? "") ?? .system
        }
        set {
            lock.lock(); defer { lock.unlock() }
            defaults.set(newValue.rawValue, forKey: Keys.appearanceMode)
        }
    }

    public var editorTheme: EditorTheme {
        get {
            lock.lock(); defer { lock.unlock() }
            return EditorTheme(rawValue: defaults.string(forKey: Keys.editorTheme) ?? "") ?? .system
        }
        set {
            lock.lock(); defer { lock.unlock() }
            defaults.set(newValue.rawValue, forKey: Keys.editorTheme)
        }
    }

    public var editorFontSize: Double {
        get {
            lock.lock(); defer { lock.unlock() }
            let value = defaults.double(forKey: Keys.editorFontSize)
            return value == 0 ? 13.0 : value
        }
        set {
            lock.lock(); defer { lock.unlock() }
            defaults.set(newValue, forKey: Keys.editorFontSize)
        }
    }

    public var autoSaveEnabled: Bool {
        get {
            lock.lock(); defer { lock.unlock() }
            if defaults.object(forKey: Keys.autoSaveEnabled) == nil { return true }
            return defaults.bool(forKey: Keys.autoSaveEnabled)
        }
        set {
            lock.lock(); defer { lock.unlock() }
            defaults.set(newValue, forKey: Keys.autoSaveEnabled)
        }
    }

    public var defaultAIProvider: String {
        get {
            lock.lock(); defer { lock.unlock() }
            return defaults.string(forKey: Keys.defaultAIProvider) ?? "claude"
        }
        set {
            lock.lock(); defer { lock.unlock() }
            defaults.set(newValue, forKey: Keys.defaultAIProvider)
        }
    }

    public var pdfRememberLastPage: Bool {
        get {
            lock.lock(); defer { lock.unlock() }
            if defaults.object(forKey: Keys.pdfRememberLastPage) == nil { return true }
            return defaults.bool(forKey: Keys.pdfRememberLastPage)
        }
        set {
            lock.lock(); defer { lock.unlock() }
            defaults.set(newValue, forKey: Keys.pdfRememberLastPage)
        }
    }

    public var cliColorOutput: Bool {
        get {
            lock.lock(); defer { lock.unlock() }
            if defaults.object(forKey: Keys.cliColorOutput) == nil { return true }
            return defaults.bool(forKey: Keys.cliColorOutput)
        }
        set {
            lock.lock(); defer { lock.unlock() }
            defaults.set(newValue, forKey: Keys.cliColorOutput)
        }
    }

    // MARK: - Recent files (PDFs and code files), most recent first, capped.

    public func recentPDFs() -> [URL] {
        lock.lock(); defer { lock.unlock() }
        let paths = defaults.stringArray(forKey: Keys.recentPDFs) ?? []
        return paths.map { URL(fileURLWithPath: $0) }.filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    public func addRecentPDF(_ url: URL, cap: Int = 20) {
        lock.lock(); defer { lock.unlock() }
        var paths = defaults.stringArray(forKey: Keys.recentPDFs) ?? []
        paths.removeAll { $0 == url.path }
        paths.insert(url.path, at: 0)
        if paths.count > cap { paths = Array(paths.prefix(cap)) }
        defaults.set(paths, forKey: Keys.recentPDFs)
    }

    public func recentFiles() -> [URL] {
        lock.lock(); defer { lock.unlock() }
        let paths = defaults.stringArray(forKey: Keys.recentFiles) ?? []
        return paths.map { URL(fileURLWithPath: $0) }.filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    public func addRecentFile(_ url: URL, cap: Int = 20) {
        lock.lock(); defer { lock.unlock() }
        var paths = defaults.stringArray(forKey: Keys.recentFiles) ?? []
        paths.removeAll { $0 == url.path }
        paths.insert(url.path, at: 0)
        if paths.count > cap { paths = Array(paths.prefix(cap)) }
        defaults.set(paths, forKey: Keys.recentFiles)
    }

    // MARK: - Last opened page per PDF (keyed by absolute path).

    public func lastPage(forPDF url: URL) -> Int? {
        lock.lock(); defer { lock.unlock() }
        let map = defaults.dictionary(forKey: Keys.lastPageByDocument) as? [String: Int] ?? [:]
        return map[url.path]
    }

    public func setLastPage(_ page: Int, forPDF url: URL) {
        lock.lock(); defer { lock.unlock() }
        var map = defaults.dictionary(forKey: Keys.lastPageByDocument) as? [String: Int] ?? [:]
        map[url.path] = page
        defaults.set(map, forKey: Keys.lastPageByDocument)
    }

    // MARK: - Per-provider overrides (base URL for OpenAI-compatible hosts, selected model).

    public func baseURLOverride(forProvider id: String) -> URL? {
        lock.lock(); defer { lock.unlock() }
        let map = defaults.dictionary(forKey: Keys.providerBaseURLOverrides) as? [String: String] ?? [:]
        guard let string = map[id] else { return nil }
        return URL(string: string)
    }

    public func setBaseURLOverride(_ url: URL?, forProvider id: String) {
        lock.lock(); defer { lock.unlock() }
        var map = defaults.dictionary(forKey: Keys.providerBaseURLOverrides) as? [String: String] ?? [:]
        if let url {
            map[id] = url.absoluteString
        } else {
            map.removeValue(forKey: id)
        }
        defaults.set(map, forKey: Keys.providerBaseURLOverrides)
    }

    public func selectedModel(forProvider id: String) -> String? {
        lock.lock(); defer { lock.unlock() }
        let map = defaults.dictionary(forKey: Keys.providerModelSelection) as? [String: String] ?? [:]
        return map[id]
    }

    public func setSelectedModel(_ model: String, forProvider id: String) {
        lock.lock(); defer { lock.unlock() }
        var map = defaults.dictionary(forKey: Keys.providerModelSelection) as? [String: String] ?? [:]
        map[id] = model
        defaults.set(map, forKey: Keys.providerModelSelection)
    }
}
