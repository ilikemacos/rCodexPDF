import SwiftUI
import RCodexPDFCore

struct UpdateSheet: View {
    @ObservedObject var viewModel: UpdateViewModel

    var body: some View {
        Group {
            if let progress = viewModel.installProgress {
                InstallingView(progress: progress)
            } else if let errorMessage = viewModel.errorMessage {
                UpdateErrorView(message: errorMessage) { viewModel.dismiss() }
            } else if case .updateAvailable(let release) = viewModel.availability {
                UpdateAvailableDetailView(release: release, viewModel: viewModel)
            } else if case .upToDate(let current) = viewModel.availability {
                UpToDateView(currentVersion: current) { viewModel.dismiss() }
            }
        }
        .frame(width: 420)
        .padding(24)
    }
}

private struct UpdateAvailableDetailView: View {
    let release: GitHubReleaseInfo
    @ObservedObject var viewModel: UpdateViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("A new version of rCodexPDF is available")
                        .font(.headline)
                    Text("Version \(release.version) (you have \(RCodexPDFVersion.current))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let body = release.body, !body.isEmpty {
                ScrollView {
                    Text(body)
                        .font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 160)
                .padding(8)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            HStack {
                Button("Skip This Version") { viewModel.skip(release) }
                Button("View Release Notes") { viewModel.openReleasePage(release) }
                Spacer()
                Button("Later") { viewModel.dismiss() }
                Button("Update Now") { viewModel.installUpdate(release) }
                    .buttonStyle(.borderedProminent)
                    .disabled(release.macOSZipAsset == nil)
            }
        }
    }
}

private struct InstallingView: View {
    let progress: AutoUpdateProgress

    var label: String {
        switch progress {
        case .downloading(let fraction): return "Downloading update… \(Int(fraction * 100))%"
        case .extracting: return "Extracting…"
        case .installing: return "Installing…"
        case .relaunching: return "Relaunching rCodexPDF…"
        }
    }

    var fraction: Double? {
        if case .downloading(let f) = progress { return f }
        return nil
    }

    var body: some View {
        VStack(spacing: 16) {
            if let fraction {
                ProgressView(value: fraction)
            } else {
                ProgressView()
            }
            Text(label).font(.callout).foregroundStyle(.secondary)
        }
        .padding(.vertical, 20)
    }
}

private struct UpToDateView: View {
    let currentVersion: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.green)
            Text("You're up to date").font(.headline)
            Text("rCodexPDF \(currentVersion) is the latest version.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("OK", action: onDismiss).buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 8)
    }
}

private struct UpdateErrorView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.orange)
            Text("Couldn't check for updates").font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("OK", action: onDismiss).buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 8)
    }
}
