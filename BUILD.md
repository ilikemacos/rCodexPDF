# Building rCodexPDF from source

## Prerequisites

- macOS 13+ 
- Xcode 15+ **or** Xcode Command Line Tools with a matching Swift 5.9+ toolchain (`xcode-select --install`)
- Swift Package Manager (bundled with the above — no separate install)

Verify your toolchain:
```bash
swift --version   # should report Swift 5.9 or later
```

## Quick build

```bash
git clone https://github.com/ilikemacos/rCodexPDF.git
cd rCodexPDF
swift build -c release
```

Run the app directly (development mode, unbundled window):
```bash
swift run RCodexPDF
```

Run the CLI directly:
```bash
swift run rcodexpdf -- --help
```

Run the test suite:
```bash
swift test
```

## Producing a real .app bundle, DMG, PKG, and ZIP

`swift build` alone produces bare executables, not a double-clickable `.app`. Use the packaging scripts:

```bash
./Scripts/build-app.sh        # -> dist/rCodexPDF.app (universal arm64+x86_64, ad-hoc signed)
./Scripts/make-dmg.sh         # -> dist/rCodexPDF-X.Y.Z.dmg
./Scripts/make-pkg.sh         # -> dist/rCodexPDF-X.Y.Z.pkg
./Scripts/make-zip.sh         # -> dist/rCodexPDF-X.Y.Z-macOS.zip
./Scripts/make-source-archive.sh   # -> dist/rCodexPDF-X.Y.Z-source.tar.gz

# or all of the above in one go:
./Scripts/release-all.sh
```

`build-app.sh` builds a universal binary via `swift build --arch arm64 --arch x86_64`. For a faster local iteration loop on just your machine's architecture:
```bash
SKIP_UNIVERSAL=1 ./Scripts/build-app.sh
```

## Signing & notarization

By default, `build-app.sh` ad-hoc signs (`codesign --sign -`), which runs fine locally but triggers a Gatekeeper warning for anyone else who downloads it (see [INSTALL.md](INSTALL.md#gatekeeper)).

To sign with a real Developer ID Application certificate:
```bash
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./Scripts/build-app.sh
INSTALLER_SIGN_IDENTITY="Developer ID Installer: Your Name (TEAMID)" ./Scripts/make-pkg.sh
```

To notarize a signed DMG/PKG (requires a one-time `xcrun notarytool store-credentials` setup — see comments in the script):
```bash
./Scripts/notarize.sh dist/rCodexPDF-X.Y.Z.dmg
./Scripts/notarize.sh dist/rCodexPDF-X.Y.Z.pkg
```

CI (`.github/workflows/release.yml`) picks up `CODESIGN_IDENTITY`, `INSTALLER_SIGN_IDENTITY`, and notarization credentials from repository secrets automatically, if configured; otherwise it produces an ad-hoc-signed, non-notarized release, which is a normal and expected state for a community open-source project without a paid Apple Developer account.

## Project layout

```
Sources/
  RCodexPDFCore/            # Platform-agnostic core, shared by the app and the CLI
    Settings/                 AppSettings — UserDefaults-backed preferences
    Storage/                  ApplicationSupport paths, JSON file store, chat history store
    Logging/                  os.Logger wrapper + file log
    PDF/                      PDFService (PDFKit wrapper), outline/search models
    Compiler/                 ProgrammingLanguage, BuildPlanner, CompilerEngine, CodeFormatter
    AI/                       AIProvider protocol, KeychainStore, 7 provider implementations,
                               AIProviderRegistry, ChatController
    Networking/                SSEClient (Server-Sent-Events streaming)
    Models/                    Chat message/conversation models

  RCodexPDFApp/              # SwiftUI + AppKit GUI application (executable target "RCodexPDF")
    AppState.swift             Top-level app state / navigation
    Models/                    OpenPDFDocument, OpenCodeFile (per-tab view models)
    Views/PDF/                 PDF viewer, thumbnails, outline, search bar
    Views/Editor/               Code editor (NSTextView), syntax highlighter, minimap, build output
    Views/Chat/                 Chat UI, markdown renderer, conversation list
    Views/Common/                Preferences, AI provider settings

  rcodexpdf/                 # CLI (executable target "rcodexpdf", swift-argument-parser)
    Commands/                  open, pdf, compile, chat, config, update, uninstall
    Support/                   ANSI color output, secure (hidden) input, app launcher, version

Tests/
  RCodexPDFCoreTests/        Unit tests for settings, storage, compiler planning, providers
  CLITests/                  CLI argument-parsing and command-behavior tests

Scripts/                    Packaging: build-app.sh, make-dmg.sh, make-pkg.sh, make-zip.sh,
                             make-source-archive.sh, notarize.sh, release-all.sh, generate_icon.swift
Resources/                  Info.plist template, entitlements, generated app icon
```

## Language toolchains

The code editor's Run/Compile feature shells out to whichever toolchains you have installed — it does not bundle any compiler. Install what you need, e.g.:
```bash
xcode-select --install                 # clang, clang++, swift, swiftc
brew install rust go node python       # rustc, go, node/tsc, python3
brew install openjdk kotlin dotnet php ruby
```
If a required tool is missing, rCodexPDF reports exactly which command it looked for instead of failing silently.

## Editing in an IDE

Since this is a plain SwiftPM package (no `.xcodeproj`), you can open the folder directly in Xcode (`File → Open…` on the folder, or `xed .`) and it will generate its own workspace for editing/debugging without checking anything extra into the repo.
