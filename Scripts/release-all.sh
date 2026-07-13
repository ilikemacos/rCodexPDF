#!/usr/bin/env bash
# Convenience wrapper: builds the app and every distribution artifact (DMG, PKG, ZIP, source
# archive) into dist/. This is what Scripts/ci is for; run it locally to sanity-check a release.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

"$ROOT_DIR/Scripts/build-app.sh"
"$ROOT_DIR/Scripts/make-dmg.sh"
"$ROOT_DIR/Scripts/make-pkg.sh"
"$ROOT_DIR/Scripts/make-zip.sh"
"$ROOT_DIR/Scripts/make-source-archive.sh"

echo "==> All artifacts built in dist/"
ls -la dist
