# Security Policy

## Reporting a vulnerability

If you discover a security vulnerability in rCodexPDF, please **do not open a public GitHub issue**. Instead:

- Use GitHub's [private vulnerability reporting](https://github.com/ilikemacos/rCodexPDF/security/advisories/new) for this repository, or
- Email the maintainers (see the repository's GitHub profile for contact info) with details.

Please include:
- A description of the vulnerability and its potential impact
- Steps to reproduce (proof-of-concept if possible)
- The rCodexPDF version and macOS version affected

We aim to acknowledge reports within a few days and to release a fix as soon as reasonably possible. Please give us a reasonable amount of time to address the issue before any public disclosure.

## Supported versions

Only the latest released version of rCodexPDF receives security fixes.

## Security design notes

- **API keys** (Claude, ChatGPT, Gemini, OpenRouter, Grok, Hermes, Llama) are stored exclusively in the **macOS Keychain** (`kSecClassGenericPassword`), never in `UserDefaults`, plain-text config files, or logs. See `Sources/RCodexPDFCore/AI/KeychainStore.swift`.
- Chat history, settings, and recent-file lists are stored locally under `~/Library/Application Support/rCodexPDF/` and are never transmitted anywhere except to the AI provider you explicitly send a message to.
- The **compile & run** feature executes arbitrary code you open or write, using your machine's own compilers/interpreters. This is inherent to being a code editor/IDE — treat source files from untrusted sources with the same caution you would in any other IDE or terminal.
- rCodexPDF makes outbound network requests only to: (a) the AI provider endpoints you configure, when you send a chat message, and (b) GitHub's release API/raw content, when you run `rcodexpdf update` or the installer. It does not phone home or collect telemetry.
- The app is not sandboxed (see `Resources/rCodexPDF.entitlements` for why — the compiler feature needs to spawn arbitrary developer toolchains), so please only build/run source you trust, same as you would with any other developer tool.

## Dependencies

rCodexPDF's only external dependency is [swift-argument-parser](https://github.com/apple/swift-argument-parser) (Apple, Apache 2.0), used by the CLI. Dependabot/Renovate-style dependency update PRs are welcome.
