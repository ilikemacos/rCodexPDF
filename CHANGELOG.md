# Changelog

All notable changes to rCodexPDF are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project uses [Semantic Versioning](https://semver.org/).

## [1.1.0] - 2026-07-13

### Added
- **Auto-update**: the app checks for a new release automatically once a day (and always on manual "Check for Updates…" from the app menu or Settings), shows an in-app sheet with release notes, and can download + install the update in place — including prompting for admin rights via the system dialog if `/Applications` isn't user-writable — then relaunches. A "Skip This Version" option persists per-version.
- Update-checking logic (`UpdateChecker`) now lives in `RCodexPDFCore` and is shared by both the GUI's auto-updater and the CLI's `rcodexpdf update`, instead of being duplicated.
- **In-window Settings tab**: replaces the old macOS Preferences window with a sidebar tab (⌘,) with pill-style sub-navigation — Appearance, AI Providers, General — matching the rest of the app.
- **Interface language**: a real, working language picker (English, Español, Français, Deutsch, 日本語) that translates the sidebar and Settings screen via a key-based translation table (`RCodexPDFCore.Localization`); other screens currently remain English-only rather than showing a half-translated mix.
- **Interface font size**: a Small/Medium/Large/XL picker that scales UI text app-wide via SwiftUI's Dynamic Type, separate from the code editor's own font size setting.

## [1.0.0] - 2026-07-13

### Added
- Initial public release.
- **PDF viewer**: PDFKit-based rendering, tabs, zoom/rotate/fullscreen, full-text search with highlighting, text selection & copy, printing, thumbnail and outline/bookmark sidebars, password-protected PDF support, drag & drop, recent files, remembers last page per document, light/dark mode.
- **Code editor & compiler**: syntax highlighting, line numbers, bracket matching, code folding, minimap, keyword/identifier autocomplete, find & replace, multi-tab editing, auto-save, format-on-demand. Compile & run support for C, C++, Rust, Go, Python, Java, JavaScript, TypeScript, Swift, Kotlin, C#, PHP, Ruby, and Bash, with a live build output panel, parsed compiler diagnostics, and Run/Stop controls.
- **AI chat assistant**: Claude, ChatGPT, Gemini, OpenRouter, Grok, Hermes, and Llama providers with streaming responses, Markdown + syntax-highlighted code rendering, Keychain-backed API key storage, conversation history with search, Markdown/JSON export and import, and token usage/cost tracking.
- **CLI (`rcodexpdf`)**: `open`, `pdf`, `compile`, `chat`, `config`, `update`, `uninstall` commands; colored output; Bash/Zsh completion generation; structured logging to `~/Library/Application Support/rCodexPDF` and `~/Library/Logs/rCodexPDF`.
- **Installation**: `install.sh` one-line installer (architecture detection, dependency checks, PATH setup, update/uninstall support), plus DMG, PKG, and ZIP distribution artifacts.
- **CI/CD**: GitHub Actions build/test/shellcheck on every PR, tag-triggered release workflow producing DMG/PKG/ZIP/source archive with optional code signing and notarization.

### Known limitations
- No multi-file project/workspace build support yet (single source file compile & run only).
- Code completion is keyword + in-buffer-identifier based, not a full language server.
- Lua is intentionally not supported.
