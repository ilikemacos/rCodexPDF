# rCodexPDF

> All-in-one macOS app: a fast native PDF viewer, a code editor with real compile/run for 14 languages, and a multi-provider AI chat assistant. Open source, no account, API keys stay in your Keychain.

**[→ Releases](https://github.com/chopsticks/rCodexPDF/releases)**

### Quick install (Terminal)

```bash
curl -fsSL https://raw.githubusercontent.com/chopsticks/rCodexPDF/main/install.sh | bash
```

### Homebrew

```bash
brew tap chopsticks/rcodexpdf
brew install rcodexpdf
```

If Homebrew reports permission errors on `/opt/homebrew`, run `sudo chown -R "$(whoami)" /opt/homebrew/Cellar /opt/homebrew/Library` and try again. Or use the [install script](https://github.com/chopsticks/homebrew-rcodexpdf/blob/main/install.sh) (same result, no Homebrew).

---

## Download (GitHub Releases)

Each release includes an **App ZIP** (with `rCodexPDF.app`), **PKG**, **DMG**, and a **source archive**.

### v1.0.0

| Format | File |
|--------|------|
| **App ZIP** | [rCodexPDF-1.0.0-macOS.zip](https://github.com/chopsticks/rCodexPDF/releases/download/v1.0.0/rCodexPDF-1.0.0-macOS.zip) |
| **PKG** | [rCodexPDF-1.0.0.pkg](https://github.com/chopsticks/rCodexPDF/releases/download/v1.0.0/rCodexPDF-1.0.0.pkg) |
| **DMG** | [rCodexPDF-1.0.0.dmg](https://github.com/chopsticks/rCodexPDF/releases/download/v1.0.0/rCodexPDF-1.0.0.dmg) |
| **Source** | [rCodexPDF-1.0.0-source.tar.gz](https://github.com/chopsticks/rCodexPDF/releases/download/v1.0.0/rCodexPDF-1.0.0-source.tar.gz) |

[All releases →](https://github.com/chopsticks/rCodexPDF/releases)

### Install from App ZIP

1. Download the `.zip` (or `.dmg`/`.pkg`)
2. Unzip → drag **rCodexPDF.app** into **Applications** (the PKG does this for you, plus installs the CLI)
3. First launch: right-click → **Open** → **Open** (once) if Gatekeeper blocks it — see [INSTALL.md](INSTALL.md#gatekeeper)

---

## What it does

- **PDF viewer** — PDFKit rendering, tabs, zoom/rotate/fullscreen, full-text search with highlighting, text selection & copy, printing, thumbnail + outline/bookmark sidebars, password-protected PDFs, drag & drop, recent files, remembers your last page, light/dark mode
- **Code editor & compiler** — syntax highlighting, line numbers, bracket matching, code folding, minimap, keyword/identifier autocomplete, find & replace, multi-tab, auto-save, on-demand formatting. Compiles & runs **C, C++, Rust, Go, Python, Java, JavaScript, TypeScript, Swift, Kotlin, C#, PHP, Ruby, Bash** using your machine's own toolchains — live build output, parsed diagnostics, Run/Stop. (No Lua, by design.)
- **AI chat** — bring your own key for **Claude, ChatGPT, Gemini, OpenRouter, Grok, Hermes, Llama**. Streaming responses, Markdown + syntax-highlighted code, conversation history with search, Markdown/JSON export & import, token/cost tracking. Keys live only in the macOS **Keychain**, never on disk.
- **CLI** — `rcodexpdf` ships alongside the app: `open`, `pdf`, `compile`, `chat`, `config`, `update`, `uninstall`, colored output, Bash/Zsh completions.
- **Auto-update** — the app checks GitHub Releases once a day (or on demand via **Check for Updates…**), and can download, install, and relaunch in place, prompting for admin rights only if needed.

```
rcodexpdf                       # launch the app
rcodexpdf open document.pdf     # open a PDF or code file in the app
rcodexpdf pdf document.pdf      # open a PDF (or --info/--text/--search for headless use)
rcodexpdf compile main.cpp      # compile & run a source file, streaming output, real exit codes
rcodexpdf chat                  # interactive AI chat REPL in the terminal
rcodexpdf config                # view/change settings and manage stored API keys
rcodexpdf update                # check for and install the latest release
rcodexpdf uninstall             # remove rCodexPDF (--purge to also remove data/API keys)
```

---

## Requirements

- macOS 13 (Ventura) or later
- Apple Silicon or Intel Mac (universal binary)

---

## Open source

This repository contains the full rCodexPDF source tree — a plain Swift Package (no `.xcodeproj` needed):

| Path | What it is |
|------|------------|
| `Sources/RCodexPDFCore/` | Shared core: Settings, Storage, Logging, PDF engine, Compiler engine, 7 AI providers, Keychain, auto-updater |
| `Sources/RCodexPDFApp/` | The SwiftUI + AppKit GUI app |
| `Sources/rcodexpdf/` | The CLI (swift-argument-parser) |
| `Tests/` | Unit tests for both |
| `Scripts/` | `build-app.sh`, `make-dmg.sh`, `make-pkg.sh`, `make-zip.sh`, `make-source-archive.sh`, `notarize.sh`, `release-all.sh`, `generate_icon.swift` |
| `Resources/` | Info.plist template, entitlements, generated app icon |
| `install.sh` | One-line installer (this repo's `main` branch) |
| `.github/workflows/` | CI (build+test+shellcheck) and tag-triggered release (DMG/PKG/ZIP/source archive) |

The Homebrew tap lives at [chopsticks/homebrew-rcodexpdf](https://github.com/chopsticks/homebrew-rcodexpdf). Pre-built `.zip`, `.pkg`, and `.dmg` files are published on [GitHub Releases](https://github.com/chopsticks/rCodexPDF/releases), not committed here.

### Build from source (macOS)

```bash
git clone https://github.com/chopsticks/rCodexPDF.git
cd rCodexPDF
swift build -c release
```

Requires Xcode 15+ or Command Line Tools with Swift 5.9+ (`xcode-select --install`). Full instructions, including producing a signed `.app`/DMG/PKG, are in [BUILD.md](BUILD.md).

### Documentation

- [INSTALL.md](INSTALL.md) — installation, updating, uninstalling, troubleshooting
- [BUILD.md](BUILD.md) — building from source, project layout, developer setup
- [CONTRIBUTING.md](CONTRIBUTING.md) — how to contribute
- [SECURITY.md](SECURITY.md) — reporting vulnerabilities, API key handling
- [CHANGELOG.md](CHANGELOG.md) — release history

### Known limitations (v1.0.0)

- No multi-file project/workspace support yet (single-file compile & run only)
- Code completion is keyword + in-buffer-identifier based, not a full language server
- Hermes and Llama have no single official hosted API; defaults point at OpenRouter/Groq and are user-configurable
- Ad-hoc-signed builds trigger a one-time Gatekeeper warning unless a maintainer configures a Developer ID + notarization (see [BUILD.md](BUILD.md#signing--notarization))

---

## License

[MIT](LICENSE)
