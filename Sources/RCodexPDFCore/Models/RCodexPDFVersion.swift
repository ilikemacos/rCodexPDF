import Foundation

/// Single source of truth for the CLI/app version, kept in sync with `CHANGELOG.md` and git tags.
/// `Scripts/build-app.sh` and the release workflow parse this same string via `grep`.
public enum RCodexPDFVersion {
    public static let current = "1.1.0"
}
