# Contributing to rCodexPDF

Thanks for considering a contribution! rCodexPDF is a community-driven, MIT-licensed project.

## Before you start

- For a substantial change (new feature, architectural change), please open an issue or discussion first to agree on the approach before investing time in a PR.
- For bug fixes and small improvements, feel free to open a PR directly.
- Check existing issues/PRs to avoid duplicate work.

## Development setup

See [BUILD.md](BUILD.md) for building the project. In short:
```bash
git clone https://github.com/rcodexpdf/rCodexPDF.git
cd rCodexPDF
swift build
swift test
```

## Code style

- Match the existing style in the file you're editing (this project doesn't use SwiftLint/SwiftFormat config beyond what's in the repo yet — contributions adding one are welcome).
- Keep `RCodexPDFCore` free of AppKit/SwiftUI imports where possible, so it stays usable from both the GUI app and the CLI. `PDFService` is an intentional exception (it wraps PDFKit, which some CLI commands also need).
- Prefer small, focused PRs over large ones that touch many unrelated areas.
- No new dependencies without discussion first — this project intentionally keeps its dependency footprint minimal (currently just `swift-argument-parser`).
- Do not add Lua support — it's explicitly out of scope for this project.

## Testing

- Add or update unit tests in `Tests/RCodexPDFCoreTests` or `Tests/CLITests` for any behavior change in `RCodexPDFCore` or the CLI.
- For UI changes, describe how you manually tested them in the PR description (screenshots/GIFs are very helpful).
- Run `swift test` and make sure it passes before opening a PR.

## Commit / PR conventions

- Write commit messages that explain *why*, not just *what*.
- Fill out the PR template's checklist honestly — an unchecked box is fine, a false checkmark isn't.
- One logical change per PR where practical.

## Reporting bugs / requesting features

Use the issue templates under **Issues → New Issue**. Include your macOS version, chip (Apple Silicon/Intel), rCodexPDF version (`rcodexpdf --version`), and relevant logs from `~/Library/Logs/rCodexPDF/rcodexpdf.log`.

## Security issues

Please do **not** open a public issue for a security vulnerability — see [SECURITY.md](SECURITY.md) instead.

## License

By contributing, you agree that your contributions will be licensed under the MIT License (see [LICENSE](LICENSE)).
