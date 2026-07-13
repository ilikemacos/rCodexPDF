# Installing rCodexPDF

## Requirements

- macOS 13 (Ventura) or later
- Apple Silicon or Intel Mac

## Option 1: One-line installer (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/ilikemacos/rCodexPDF/main/install.sh | bash
```

This script:
1. Detects Apple Silicon vs Intel and your macOS version.
2. Checks for Xcode Command Line Tools (recommended for the code editor's C/C++ compilation; other languages need their own toolchains — see [BUILD.md](BUILD.md#language-toolchains)).
3. Downloads the latest release, or builds from source with `--from-source`.
4. Installs `rCodexPDF.app` to `/Applications`.
5. Installs the `rcodexpdf` CLI to `/usr/local/bin` (falls back to `~/.local/bin` if that isn't writable) and adds it to your `PATH`.
6. Installs Bash/Zsh completions.

Re-running the same command updates an existing install in place.

Useful flags (pass after `bash -s --`):
```bash
curl -fsSL .../install.sh | bash -s -- --from-source     # build locally instead of downloading
curl -fsSL .../install.sh | bash -s -- --version 1.0.0    # install a specific version
curl -fsSL .../install.sh | bash -s -- --uninstall        # remove rCodexPDF
```

## Option 2: DMG

1. Download `rCodexPDF-X.Y.Z.dmg` from [Releases](https://github.com/ilikemacos/rCodexPDF/releases).
2. Open it and drag `rCodexPDF.app` to `Applications`.
3. To also get the `rcodexpdf` CLI, launch the app once, or copy it out of the bundle:
   ```bash
   sudo cp /Applications/rCodexPDF.app/Contents/Resources/bin/rcodexpdf /usr/local/bin/rcodexpdf
   ```

## Option 3: PKG

1. Download `rCodexPDF-X.Y.Z.pkg` from [Releases](https://github.com/ilikemacos/rCodexPDF/releases).
2. Double-click and follow the installer. This installs both the app **and** the CLI (with shell completions) in one step — no manual PATH setup needed.

## Option 4: ZIP

Download `rCodexPDF-X.Y.Z-macOS.zip`, unzip, and move `rCodexPDF.app` to `/Applications` yourself. The CLI binary is at `Contents/Resources/bin/rcodexpdf` inside the bundle, same as the DMG.

## Gatekeeper

Unsigned/ad-hoc release builds (i.e. built without a maintainer's paid Apple Developer ID) will show a Gatekeeper warning on first launch: *"rCodexPDF" can't be opened because it is from an unidentified developer.* To open it anyway:

- Right-click (or Control-click) `rCodexPDF.app` → **Open** → **Open**, or
- **System Settings → Privacy & Security** → click **Open Anyway** next to the rCodexPDF warning.

`install.sh` and the `.pkg` both clear the quarantine attribute automatically, so this typically only matters for a manually downloaded DMG/ZIP. Official releases built with a configured Developer ID + notarization (see [BUILD.md](BUILD.md#signing--notarization)) don't show this warning.

## Updating

```bash
rcodexpdf update
```
or simply re-run the install script.

## Uninstalling

```bash
rcodexpdf uninstall            # removes the app and CLI, keeps your chat history/settings/API keys
rcodexpdf uninstall --purge    # also removes chat history, settings, and Keychain API keys
```
or:
```bash
curl -fsSL https://raw.githubusercontent.com/ilikemacos/rCodexPDF/main/install.sh | bash -s -- --uninstall
```

## Troubleshooting

**"rcodexpdf: command not found" after installing**
Open a new terminal window/tab (or `source ~/.zshrc`) so the `PATH` update from the installer takes effect.

**Compile/Run fails with "toolchain not found"**
rCodexPDF shells out to your machine's own compilers/interpreters (clang, rustc, go, python3, javac, node, tsc, swiftc, kotlinc, dotnet, php, ruby, bash). Install the one you need, e.g. via [Homebrew](https://brew.sh): `brew install rust go node` etc. Swift and clang/clang++ ship with Xcode Command Line Tools (`xcode-select --install`).

**AI chat says "No API key configured"**
Open **Preferences → AI Providers** in the app (or run `rcodexpdf config set-key <provider>` in the terminal) and add a key for the provider you selected. Keys are stored in the macOS Keychain, never in a plain-text file.

**Still stuck?** [Open an issue](https://github.com/ilikemacos/rCodexPDF/issues) with your macOS version, chip, and `~/Library/Logs/rCodexPDF/rcodexpdf.log`.
