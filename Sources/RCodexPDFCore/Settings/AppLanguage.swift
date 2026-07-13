import Foundation

/// Supported interface languages. Adding a language means adding one case here and one
/// dictionary in `Localization.strings` — nothing else has to change.
public enum AppLanguage: String, Codable, CaseIterable, Sendable, Identifiable {
    case en, es, fr, de, ja, zhHant

    public var id: String { rawValue }

    public var nativeLabel: String {
        switch self {
        case .en: return "English"
        case .es: return "Español"
        case .fr: return "Français"
        case .de: return "Deutsch"
        case .ja: return "日本語"
        case .zhHant: return "繁體中文"
        }
    }
}

public enum UIFontSizePreset: String, Codable, CaseIterable, Sendable, Identifiable {
    case small, medium, large, extraLarge

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .small: return "S"
        case .medium: return "M"
        case .large: return "L"
        case .extraLarge: return "XL"
        }
    }
}
