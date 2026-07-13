import Foundation

/// A small, real key-based translation table for the app's navigation and Settings screen
/// (the surfaces most people actually change language for). Not a claim of full app-wide
/// localization — every key here genuinely changes what's on screen when the language changes;
/// unrouted screens fall back to English rather than showing a mix of half-translated text.
public enum Localization {
    private static let table: [String: [AppLanguage: String]] = [
        "sidebar.pdf": [.en: "PDF Viewer", .es: "Visor de PDF", .fr: "Lecteur PDF", .de: "PDF-Betrachter", .ja: "PDFビューア"],
        "sidebar.editor": [.en: "Code Editor", .es: "Editor de Código", .fr: "Éditeur de Code", .de: "Code-Editor", .ja: "コードエディタ"],
        "sidebar.chat": [.en: "AI Chat", .es: "Chat IA", .fr: "Chat IA", .de: "KI-Chat", .ja: "AIチャット"],
        "sidebar.settings": [.en: "Settings", .es: "Ajustes", .fr: "Réglages", .de: "Einstellungen", .ja: "設定"],
        "sidebar.workspace": [.en: "Workspace", .es: "Espacio de trabajo", .fr: "Espace de travail", .de: "Arbeitsbereich", .ja: "ワークスペース"],
        "sidebar.recentPDFs": [.en: "Recent PDFs", .es: "PDF recientes", .fr: "PDF récents", .de: "Zuletzt geöffnete PDFs", .ja: "最近のPDF"],
        "sidebar.recentFiles": [.en: "Recent Files", .es: "Archivos recientes", .fr: "Fichiers récents", .de: "Zuletzt geöffnete Dateien", .ja: "最近のファイル"],

        "settings.title": [.en: "Settings", .es: "Ajustes", .fr: "Réglages", .de: "Einstellungen", .ja: "設定"],
        "settings.subtitle": [.en: "Configure rCodexPDF to your liking.", .es: "Configura rCodexPDF a tu gusto.", .fr: "Configurez rCodexPDF selon vos préférences.", .de: "Passe rCodexPDF nach deinen Wünschen an.", .ja: "rCodexPDFをお好みに設定します。"],

        "settings.section.appearance": [.en: "Appearance", .es: "Apariencia", .fr: "Apparence", .de: "Erscheinungsbild", .ja: "外観"],
        "settings.section.providers": [.en: "AI Providers", .es: "Proveedores de IA", .fr: "Fournisseurs IA", .de: "KI-Anbieter", .ja: "AIプロバイダー"],
        "settings.section.general": [.en: "General", .es: "General", .fr: "Général", .de: "Allgemein", .ja: "一般"],

        "appearance.mode": [.en: "Appearance", .es: "Apariencia", .fr: "Apparence", .de: "Darstellung", .ja: "外観モード"],
        "appearance.mode.system": [.en: "System", .es: "Sistema", .fr: "Système", .de: "System", .ja: "システム"],
        "appearance.mode.light": [.en: "Light", .es: "Claro", .fr: "Clair", .de: "Hell", .ja: "ライト"],
        "appearance.mode.dark": [.en: "Dark", .es: "Oscuro", .fr: "Sombre", .de: "Dunkel", .ja: "ダーク"],

        "appearance.fontSize": [.en: "Interface Font Size", .es: "Tamaño de fuente", .fr: "Taille de police", .de: "Schriftgröße", .ja: "フォントサイズ"],
        "appearance.language": [.en: "Language", .es: "Idioma", .fr: "Langue", .de: "Sprache", .ja: "言語"],
        "appearance.editorTheme": [.en: "Editor Theme", .es: "Tema del editor", .fr: "Thème de l'éditeur", .de: "Editor-Thema", .ja: "エディタテーマ"],
        "appearance.editorFontSize": [.en: "Editor Font Size", .es: "Tamaño de fuente del editor", .fr: "Taille de police de l'éditeur", .de: "Editor-Schriftgröße", .ja: "エディタのフォントサイズ"],

        "providers.title": [.en: "AI Providers", .es: "Proveedores de IA", .fr: "Fournisseurs IA", .de: "KI-Anbieter", .ja: "AIプロバイダー"],
        "providers.subtitle": [.en: "API keys are stored in the macOS Keychain, never in plain text.", .es: "Las claves API se guardan en el Llavero de macOS, nunca en texto plano.", .fr: "Les clés API sont stockées dans le Trousseau macOS, jamais en texte brut.", .de: "API-Schlüssel werden im macOS-Schlüsselbund gespeichert, niemals im Klartext.", .ja: "APIキーはmacOSキーチェーンに保存され、平文では保存されません。"],

        "general.rememberLastPage": [.en: "Remember last opened PDF page", .es: "Recordar última página de PDF abierta", .fr: "Se souvenir de la dernière page PDF ouverte", .de: "Zuletzt geöffnete PDF-Seite merken", .ja: "最後に開いたPDFページを記憶する"],
        "general.coloredCLI": [.en: "Colored CLI output", .es: "Salida de CLI en color", .fr: "Sortie CLI en couleur", .de: "Farbige CLI-Ausgabe", .ja: "CLI出力をカラー表示"],
        "general.autoSave": [.en: "Auto-save", .es: "Guardado automático", .fr: "Enregistrement automatique", .de: "Automatisch speichern", .ja: "自動保存"],
        "general.autoUpdate": [.en: "Automatically check for updates", .es: "Buscar actualizaciones automáticamente", .fr: "Rechercher les mises à jour automatiquement", .de: "Automatisch nach Updates suchen", .ja: "自動的にアップデートを確認する"],
        "general.checkNow": [.en: "Check for Updates Now…", .es: "Buscar actualizaciones ahora…", .fr: "Rechercher des mises à jour…", .de: "Jetzt nach Updates suchen…", .ja: "今すぐアップデートを確認…"]
    ]

    /// Looks up `key` in the current UI language, falling back to English, then to the raw key
    /// itself so a missing translation is visibly obvious in testing rather than blank.
    public static func string(_ key: String, language: AppLanguage) -> String {
        table[key]?[language] ?? table[key]?[.en] ?? key
    }
}
