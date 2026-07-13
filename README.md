# rCodexPDF

**A fast, native, all-in-one macOS app: PDF viewer + code editor/compiler + multi-provider AI chat, with a matching CLI.**

rCodexPDF is 100% open source (MIT), written in Swift with SwiftUI + AppKit, and built with the Swift Package Manager — no proprietary tooling required to build it from source.

## Features

### PDF Viewer
- PDFKit-based rendering: fast, smooth, native scrolling and zoom
- Multiple PDF tabs, drag & drop, recent files
- Zoom, page rotation, fullscreen
- Full-text search with highlighting and result navigation
- Text selection & copy, printing
- Page thumbnail sidebar and outline/bookmarks sidebar
- Password-protected PDF support
- Remembers the last page you had open, per document
- Light/dark mode, follows system appearance or overridable

### Code Editor & Compiler
- Syntax highlighting, line numbers, bracket matching, code folding, minimap
- Keyword + in-buffer identifier autocomplete (via `NSTextView`'s native completion)
- Find & replace (system find bar), multiple tabs, auto-save
- Compile & run: **C, C++, Rust, Go, Python, Java, JavaScript, TypeScript, Swift, Kotlin, C#, PHP, Ruby, Bash**
  (Lua is intentionally not supported)
- Live build output panel, parsed compiler diagnostics (clickable, file:line), Run/Stop
- Format-on-demand using each language's standard formatter (clang-format, gofmt, rustfmt, prettier, black, swift-format, rubocop, ktlint, dotnet-format), when installed

Compiling shells out to real toolchains already on your Mac. If a toolchain isn't installed, rCodexPDF tells you exactly which one and lets you install it — there's no bundled/fake compiler.

### AI Chat Assistant
- Bring your own API key for: **Claude (Anthropic), ChatGPT (OpenAI), Gemini (Google), OpenRouter, Grok (xAI), Hermes (Nous Research), Llama (Meta)**
- API keys are stored in the **macOS Keychain only** — never written to disk in plain text
- Streaming responses, Markdown + syntax-highlighted code blocks, copy-to-clipboard
- Per-conversation history, full-text search, export (Markdown/JSON) and import
- Token usage and estimated cost tracking (where pricing is known)
- Hermes and Llama endpoints are configurable (default to OpenRouter and Groq respectively) since neither has one official first-party hosted API

### CLI — `rcodexpdf`
```
rcodexpdf                       # launch the app
rcodexpdf open document.pdf     # open a PDF or code file in the app
rcodexpdf pdf document.pdf      # open a PDF (or use --info/--text/--search for headless use)
rcodexpdf compile main.cpp      # compile & run a source file, streaming output, real exit codes
rcodexpdf chat                  # interactive AI chat REPL in the terminal
rcodexpdf config                # view/change settings and manage stored API keys
rcodexpdf update                # check for and install the latest release
rcodexpdf uninstall             # remove rCodexPDF (--purge to also remove data/API keys)
```
Colored output (disabled automatically when piped, or via `NO_COLOR=1`), `--help` on every command, and Bash/Zsh completion via `rcodexpdf --generate-completion-script zsh|bash` (installed automatically by `install.sh`/the `.pkg`).

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/rcodexpdf/rCodexPDF/main/install.sh | bash
```

Or download a **DMG**, **PKG**, or **ZIP** from [Releases](https://github.com/rcodexpdf/rCodexPDF/releases). See [INSTALL.md](INSTALL.md) for details, updating, and uninstalling.

## Building from source

```bash
git clone https://github.com/rcodexpdf/rCodexPDF.git
cd rCodexPDF
swift build -c release
```
Full instructions, including producing a signed `.app`/DMG/PKG, are in [BUILD.md](BUILD.md).

## Documentation

- [INSTALL.md](INSTALL.md) — installation, updating, uninstalling, troubleshooting
- [BUILD.md](BUILD.md) — building from source, project layout, developer setup
- [CONTRIBUTING.md](CONTRIBUTING.md) — how to contribute
- [SECURITY.md](SECURITY.md) — reporting vulnerabilities, API key handling
- [CHANGELOG.md](CHANGELOG.md) — release history

## Architecture

rCodexPDF is a Swift Package with three targets sharing one core library:

```
Sources/
  RCodexPDFCore/     Settings, Storage, Logging, PDF engine, Compiler engine, AI providers
  RCodexPDFApp/       SwiftUI + AppKit GUI application
  rcodexpdf/           Command-line interface (swift-argument-parser)
```

See [BUILD.md](BUILD.md#project-layout) for a full breakdown.

## Known limitations (v1.0.0)

- No multi-file project/workspace support yet (single-file compile & run only); Makefile/Cargo/npm project builds are on the roadmap.
- Code completion is keyword + in-buffer-identifier based, not a full language server (no cross-file type inference).
- Hermes and Llama have no single official hosted API; defaults point at OpenRouter/Groq and are user-configurable.
- Official signed/notarized release builds require a maintainer with an Apple Developer ID — unsigned/ad-hoc builds work but macOS Gatekeeper will warn on first launch (see [INSTALL.md](INSTALL.md#gatekeeper)).

## License

MIT — see [LICENSE](LICENSE).
