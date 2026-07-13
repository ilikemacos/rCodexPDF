import SwiftUI
import RCodexPDFCore

extension UIFontSizePreset {
    /// Explicit multiplier applied to literal point sizes. Deliberately not relying on SwiftUI's
    /// `dynamicTypeSize`: adjacent `DynamicTypeSize` cases differ by only a point or two (and
    /// `.large` is the system default), and macOS `List`/sidebar rows don't reliably respond to
    /// it at all — so a "font size" picker built on it would visibly do nothing. Multiplying
    /// explicit sizes is unambiguous and works everywhere it's applied.
    var scale: CGFloat {
        switch self {
        case .small: return 0.85
        case .medium: return 1.0
        case .large: return 1.2
        case .extraLarge: return 1.45
        }
    }
}

private struct UIFontScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1.0
}

extension EnvironmentValues {
    /// The current interface font-size multiplier, set once at the app root from
    /// `AppSettings.uiFontSizePreset`. Read this and multiply literal point sizes rather than
    /// using semantic text styles + `dynamicTypeSize`, which macOS doesn't scale reliably.
    var uiFontScale: CGFloat {
        get { self[UIFontScaleKey.self] }
        set { self[UIFontScaleKey.self] = newValue }
    }
}
