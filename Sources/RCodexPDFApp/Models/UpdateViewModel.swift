import SwiftUI
import AppKit
import RCodexPDFCore

@MainActor
final class UpdateViewModel: ObservableObject {
    @Published var availability: UpdateAvailability?
    @Published var isChecking = false
    @Published var installProgress: AutoUpdateProgress?
    @Published var errorMessage: String?
    @Published var isPresented = false

    private let settings = AppSettings.shared
    private let updater = AutoUpdater.shared
    private static let checkInterval: TimeInterval = 24 * 3600

    /// Called once on launch. Silent unless an update is actually available (never interrupts
    /// the user with an "up to date" dialog or a network-error dialog on startup).
    func checkOnLaunchIfDue() async {
        guard settings.autoCheckForUpdates else { return }
        if let last = settings.lastUpdateCheckDate, Date().timeIntervalSince(last) < Self.checkInterval {
            return
        }
        await performCheck(interactive: false)
    }

    /// Called from the "Check for Updates…" menu item. Always shows a result, even if up to date.
    func checkManually() async {
        await performCheck(interactive: true)
    }

    private func performCheck(interactive: Bool) async {
        isChecking = true
        errorMessage = nil
        settings.lastUpdateCheckDate = Date()

        do {
            let result = try await UpdateChecker.checkForUpdate()
            isChecking = false
            switch result {
            case .upToDate:
                if interactive {
                    availability = result
                    isPresented = true
                }
            case .updateAvailable(let release):
                if !interactive, release.version == settings.skippedUpdateVersion { return }
                availability = result
                isPresented = true
            }
        } catch {
            isChecking = false
            if interactive {
                errorMessage = error.localizedDescription
                isPresented = true
            }
        }
    }

    func installUpdate(_ release: GitHubReleaseInfo) {
        installProgress = .downloading(fraction: 0)
        errorMessage = nil
        Task {
            do {
                try await updater.downloadAndInstall(release: release) { [weak self] progress in
                    Task { @MainActor in self?.installProgress = progress }
                }
                await MainActor.run { NSApp.terminate(nil) }
            } catch {
                await MainActor.run {
                    self.installProgress = nil
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func skip(_ release: GitHubReleaseInfo) {
        settings.skippedUpdateVersion = release.version
        isPresented = false
    }

    func openReleasePage(_ release: GitHubReleaseInfo) {
        NSWorkspace.shared.open(release.htmlURL)
    }

    func dismiss() {
        guard installProgress == nil else { return }
        isPresented = false
    }
}
