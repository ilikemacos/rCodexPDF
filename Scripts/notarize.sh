#!/usr/bin/env bash
# Submits a built DMG or PKG to Apple notary service and staples the ticket.
# Requires a Developer ID Application/Installer signature (see Scripts/build-app.sh
# CODESIGN_IDENTITY / Scripts/make-pkg.sh INSTALLER_SIGN_IDENTITY) and notarization
# credentials stored in the keychain via:
#   xcrun notarytool store-credentials "rcodexpdf-notary" \
#     --apple-id you@example.com --team-id TEAMID --password app-specific-password
#
# Usage: Scripts/notarize.sh dist/rCodexPDF-1.0.0.dmg
set -euo pipefail

TARGET="${1:-}"
PROFILE="${NOTARY_PROFILE:-rcodexpdf-notary}"

if [[ -z "$TARGET" || ! -f "$TARGET" ]]; then
  echo "usage: $0 <path-to-dmg-or-pkg>" >&2
  exit 1
fi

echo "==> Submitting $TARGET for notarization (profile: $PROFILE)"
xcrun notarytool submit "$TARGET" --keychain-profile "$PROFILE" --wait

echo "==> Stapling ticket"
xcrun stapler staple "$TARGET"

echo "==> Notarization complete for $TARGET"
