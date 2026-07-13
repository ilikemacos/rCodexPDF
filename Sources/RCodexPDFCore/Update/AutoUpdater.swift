import Foundation

public enum AutoUpdateError: Error, LocalizedError, Sendable {
    case noZipAsset
    case downloadFailed(String)
    case invalidArchive
    case installFailed(String)

    public var errorDescription: String? {
        switch self {
        case .noZipAsset: return "This release has no macOS app ZIP asset."
        case .downloadFailed(let reason): return "Download failed: \(reason)"
        case .invalidArchive: return "Downloaded archive did not contain rCodexPDF.app."
        case .installFailed(let reason): return "Install failed: \(reason)"
        }
    }
}

public enum AutoUpdateProgress: Sendable, Equatable {
    case downloading(fraction: Double)
    case extracting
    case installing
    case relaunching
}

/// Downloads and installs a new rCodexPDF release in place, then relaunches the app. Shared by
/// the GUI's "Update Now" button and (in spirit) the CLI's `update` command, which instead shells
/// out to `install.sh` — appropriate for a terminal context, whereas the GUI needs an in-process
/// flow that can report progress and prompt for admin rights via the system dialog when needed.
public final class AutoUpdater: NSObject, @unchecked Sendable {
    public static let shared = AutoUpdater()

    private override init() {}

    /// Downloads `release`'s macOS ZIP asset, replaces the currently running app bundle, and
    /// relaunches it. Returns only if it fails; on success the process is asked to terminate.
    public func downloadAndInstall(
        release: GitHubReleaseInfo,
        currentAppBundlePath: String = Bundle.main.bundlePath,
        onProgress: (@Sendable (AutoUpdateProgress) -> Void)? = nil
    ) async throws {
        guard let asset = release.macOSZipAsset else { throw AutoUpdateError.noZipAsset }

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("rCodexPDF-update-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let zipPath = tempDir.appendingPathComponent(asset.name)
        try await download(from: asset.browserDownloadURL, to: zipPath, onProgress: onProgress)

        onProgress?(.extracting)
        let extractedDir = tempDir.appendingPathComponent("extracted", isDirectory: true)
        try extract(zip: zipPath, to: extractedDir)

        let newAppPath = extractedDir.appendingPathComponent("rCodexPDF.app")
        guard FileManager.default.fileExists(atPath: newAppPath.path) else {
            throw AutoUpdateError.invalidArchive
        }

        onProgress?(.installing)
        try install(newApp: newAppPath, replacing: currentAppBundlePath)

        onProgress?(.relaunching)
        relaunch(at: currentAppBundlePath)
    }

    // MARK: - Download (with byte-level progress, no URLSessionDownloadDelegate needed)

    private func download(
        from url: URL,
        to destination: URL,
        onProgress: (@Sendable (AutoUpdateProgress) -> Void)?
    ) async throws {
        do {
            let (bytes, response) = try await URLSession.shared.bytes(from: url)
            let expectedLength = response.expectedContentLength
            FileManager.default.createFile(atPath: destination.path, contents: nil)
            guard let handle = FileHandle(forWritingAtPath: destination.path) else {
                throw AutoUpdateError.downloadFailed("Could not open \(destination.path) for writing")
            }
            defer { try? handle.close() }

            var received: Int64 = 0
            var buffer = Data()
            buffer.reserveCapacity(1 << 16)

            for try await byte in bytes {
                buffer.append(byte)
                if buffer.count >= 1 << 16 {
                    handle.write(buffer)
                    received += Int64(buffer.count)
                    buffer.removeAll(keepingCapacity: true)
                    if expectedLength > 0 {
                        onProgress?(.downloading(fraction: Double(received) / Double(expectedLength)))
                    }
                }
            }
            if !buffer.isEmpty {
                handle.write(buffer)
                received += Int64(buffer.count)
            }
            onProgress?(.downloading(fraction: 1.0))
        } catch let error as AutoUpdateError {
            throw error
        } catch {
            throw AutoUpdateError.downloadFailed(error.localizedDescription)
        }
    }

    // MARK: - Extract

    private func extract(zip: URL, to destination: URL) throws {
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-x", "-k", zip.path, destination.path]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw AutoUpdateError.invalidArchive
        }
    }

    // MARK: - Install (direct write, or elevated via the system admin-privileges dialog)

    private func install(newApp: URL, replacing existingAppPath: String) throws {
        let fm = FileManager.default
        let destinationParent = (existingAppPath as NSString).deletingLastPathComponent

        if fm.isWritableFile(atPath: destinationParent) {
            if fm.fileExists(atPath: existingAppPath) {
                try fm.removeItem(atPath: existingAppPath)
            }
            try fm.copyItem(atPath: newApp.path, toPath: existingAppPath)
        } else {
            // Destination (typically /Applications) isn't writable by the current user — ask the
            // OS to show its native administrator-privileges prompt. The user enters their own
            // password directly into that system dialog; this process never sees it.
            let script = """
            do shell script "rm -rf '\(existingAppPath)' && cp -R '\(newApp.path)' '\(existingAppPath)'" with administrator privileges
            """
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", script]
            let stderrPipe = Pipe()
            process.standardError = stderrPipe
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                let message = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "unknown error"
                throw AutoUpdateError.installFailed(message)
            }
        }

        _ = try? process(["/usr/bin/xattr", "-dr", "com.apple.quarantine", existingAppPath])
    }

    @discardableResult
    private func process(_ arguments: [String]) throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: arguments[0])
        process.arguments = Array(arguments.dropFirst())
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }

    private func relaunch(at path: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [path]
        try? process.run()
    }
}
