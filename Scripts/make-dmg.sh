#!/usr/bin/env bash
# Packages dist/rCodexPDF.app into a distributable DMG with a drag-to-Applications layout.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

VERSION="$(grep -o '"[0-9]*\.[0-9]*\.[0-9]*"' Sources/RCodexPDFCore/Models/RCodexPDFVersion.swift | tr -d '"' | head -1)"
APP_BUNDLE="dist/rCodexPDF.app"
DMG_STAGING="dist/dmg-staging"
DMG_PATH="dist/rCodexPDF-$VERSION.dmg"

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "error: $APP_BUNDLE not found. Run Scripts/build-app.sh first." >&2
  exit 1
fi

rm -rf "$DMG_STAGING" "$DMG_PATH"
mkdir -p "$DMG_STAGING"
cp -R "$APP_BUNDLE" "$DMG_STAGING/rCodexPDF.app"
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create -volname "rCodexPDF $VERSION" \
  -srcfolder "$DMG_STAGING" \
  -ov -format UDZO \
  "$DMG_PATH"

rm -rf "$DMG_STAGING"
echo "==> Built $DMG_PATH"
