#!/usr/bin/env bash
# Builds rCodexPDF.app (universal arm64+x86_64) and the rcodexpdf CLI binary from source,
# and assembles a proper macOS .app bundle in ./dist/.
#
# Env vars:
#   CODESIGN_IDENTITY   Developer ID Application identity to sign with (falls back to ad-hoc "-").
#   SKIP_UNIVERSAL=1    Build only for the host architecture (faster local iteration).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

VERSION="$(grep -o '"[0-9]*\.[0-9]*\.[0-9]*"' Sources/RCodexPDFCore/Models/RCodexPDFVersion.swift | tr -d '"' | head -1)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/rCodexPDF.app"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"

echo "==> Building rCodexPDF v$VERSION"

if [[ "${SKIP_UNIVERSAL:-0}" == "1" ]]; then
  echo "==> SKIP_UNIVERSAL set: building for host architecture only"
  echo "==> swift build -c release"
  swift build -c release
else
  echo "==> swift build -c release --arch arm64 --arch x86_64"
  swift build -c release --arch arm64 --arch x86_64
fi

if [[ "${SKIP_UNIVERSAL:-0}" == "1" ]]; then
  BIN_DIR=".build/release"
else
  BIN_DIR=".build/apple/Products/Release"
fi

APP_BINARY="$BIN_DIR/RCodexPDF"
CLI_BINARY="$BIN_DIR/rcodexpdf"

if [[ ! -f "$APP_BINARY" ]]; then
  echo "error: expected binary not found at $APP_BINARY" >&2
  exit 1
fi

echo "==> Assembling app bundle"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

cp "$APP_BINARY" "$APP_BUNDLE/Contents/MacOS/RCodexPDF"
chmod +x "$APP_BUNDLE/Contents/MacOS/RCodexPDF"

cp "$ROOT_DIR/Resources/Assets/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

sed "s/__VERSION__/$VERSION/g" "$ROOT_DIR/Resources/Info.plist" > "$APP_BUNDLE/Contents/Info.plist"

# Ship the CLI binary inside the bundle too, so `install.sh` can symlink it without a second build.
mkdir -p "$APP_BUNDLE/Contents/Resources/bin"
cp "$CLI_BINARY" "$APP_BUNDLE/Contents/Resources/bin/rcodexpdf"
chmod +x "$APP_BUNDLE/Contents/Resources/bin/rcodexpdf"

echo "==> Code signing (identity: $CODESIGN_IDENTITY)"
codesign --force --deep --options runtime \
  --entitlements "$ROOT_DIR/Resources/rCodexPDF.entitlements" \
  --sign "$CODESIGN_IDENTITY" \
  "$APP_BUNDLE"

codesign --force --sign "$CODESIGN_IDENTITY" "$APP_BUNDLE/Contents/Resources/bin/rcodexpdf"

echo "==> Verifying signature"
codesign --verify --deep --strict "$APP_BUNDLE" && echo "    OK"

echo "==> Built $APP_BUNDLE"
