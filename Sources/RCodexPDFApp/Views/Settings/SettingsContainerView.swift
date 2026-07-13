import SwiftUI
import RCodexPDFCore

enum SettingsSection: String, CaseIterable, Identifiable {
    case appearance, providers, general

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .appearance: return "paintbrush"
        case .providers: return "sparkles"
        case .general: return "gearshape"
        }
    }

    @MainActor
    func label(_ holder: SettingsHolder) -> String {
        switch self {
        case .appearance: return holder.tr("settings.section.appearance")
        case .providers: return holder.tr("settings.section.providers")
        case .general: return holder.tr("settings.section.general")
        }
    }
}

/// The in-window Settings tab: a pill-style sub-navigation bar above a content area, in the
/// same style as the rest of the app's tabs (rather than a separate macOS Preferences window).
struct SettingsContainerView: View {
    @ObservedObject private var holder = SettingsHolder.shared
    @Environment(\.uiFontScale) private var fontScale
    @State private var section: SettingsSection = .appearance

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(holder.tr("settings.title"))
                    .font(.system(size: 17 * fontScale, weight: .bold))
                Text(holder.tr("settings.subtitle"))
                    .font(.system(size: 12 * fontScale))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 10)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(SettingsSection.allCases) { candidate in
                        SettingsPillButton(
                            title: candidate.label(holder),
                            icon: candidate.icon,
                            isSelected: section == candidate,
                            fontScale: fontScale
                        ) {
                            section = candidate
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 10)

            Divider()

            Group {
                switch section {
                case .appearance: SettingsAppearanceSection(holder: holder)
                case .providers: ProviderSettingsView()
                case .general: SettingsGeneralSection(holder: holder)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct SettingsPillButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let fontScale: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 11 * fontScale, weight: .semibold))
                Text(title).font(.system(size: 12 * fontScale, weight: isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isSelected ? Color.accentColor.opacity(0.45) : Color.secondary.opacity(0.2), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
