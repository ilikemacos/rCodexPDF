import Foundation

public struct ReleaseAsset: Decodable, Sendable {
    public let name: String
    public let browserDownloadURL: URL

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
    }
}

public struct GitHubReleaseInfo: Decodable, Sendable {
    public let tagName: String
    public let htmlURL: URL
    public let body: String?
    public let assets: [ReleaseAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case body
        case assets
    }

    /// Version string without the leading "v" (e.g. "1.2.3" from tag "v1.2.3").
    public var version: String {
        tagName.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
    }

    /// The macOS app ZIP asset, if present (named like `rCodexPDF-1.2.3-macOS.zip`).
    public var macOSZipAsset: ReleaseAsset? {
        assets.first { $0.name.hasSuffix("-macOS.zip") }
    }
}

public enum UpdateAvailability: Sendable {
    case upToDate(current: String)
    case updateAvailable(GitHubReleaseInfo)
}

public enum UpdateCheckError: Error, LocalizedError, Sendable {
    case networkUnreachable
    case unexpectedStatus(Int)
    case decodingFailed

    public var errorDescription: String? {
        switch self {
        case .networkUnreachable: return "Could not reach the GitHub releases API."
        case .unexpectedStatus(let code): return "GitHub releases API returned HTTP \(code)."
        case .decodingFailed: return "Could not parse the GitHub release response."
        }
    }
}

/// Shared "is there a newer rCodexPDF release" logic, used by both the CLI's `update` command
/// and the GUI app's automatic/manual update checks, so the two never drift out of sync.
public enum UpdateChecker {
    public static let releasesAPIURL = URL(string: "https://api.github.com/repos/chopsticks/rCodexPDF/releases/latest")!
    public static let installScriptURL = "https://raw.githubusercontent.com/chopsticks/rCodexPDF/main/install.sh"

    public static func fetchLatestRelease(session: URLSession = .shared) async throws -> GitHubReleaseInfo {
        var request = URLRequest(url: releasesAPIURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw UpdateCheckError.networkUnreachable
        }
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw UpdateCheckError.unexpectedStatus(status)
        }
        do {
            return try JSONDecoder().decode(GitHubReleaseInfo.self, from: data)
        } catch {
            throw UpdateCheckError.decodingFailed
        }
    }

    public static func checkForUpdate(
        currentVersion: String = RCodexPDFVersion.current,
        session: URLSession = .shared
    ) async throws -> UpdateAvailability {
        let release = try await fetchLatestRelease(session: session)
        if isNewer(release.version, than: currentVersion) {
            return .updateAvailable(release)
        }
        return .upToDate(current: currentVersion)
    }

    /// Simple dotted-integer semver comparison (`1.2.10` > `1.2.9`), good enough for our tag scheme.
    public static func isNewer(_ candidate: String, than current: String) -> Bool {
        let c = candidate.split(separator: ".").compactMap { Int($0) }
        let cur = current.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(c.count, cur.count) {
            let a = i < c.count ? c[i] : 0
            let b = i < cur.count ? cur[i] : 0
            if a != b { return a > b }
        }
        return false
    }
}
