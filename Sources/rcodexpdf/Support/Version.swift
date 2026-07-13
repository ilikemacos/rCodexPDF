import Foundation

/// Single source of truth for the CLI/app version, kept in sync with `CHANGELOG.md` and git tags.
/// `Scripts/build-app.sh` and the release workflow read this same string.
enum RCodexPDFVersion {
    static let current = "1.0.0"
}
