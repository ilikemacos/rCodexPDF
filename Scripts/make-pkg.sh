#!/usr/bin/env bash
# Builds a standard macOS .pkg installer that places rCodexPDF.app in /Applications and the
# rcodexpdf CLI in /usr/local/bin, with a postinstall step that registers shell completions.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

VERSION="$(grep -o '"[0-9]*\.[0-9]*\.[0-9]*"' Sources/RCodexPDFCore/Models/RCodexPDFVersion.swift | tr -d '"' | head -1)"
APP_BUNDLE="dist/rCodexPDF.app"
PKG_ROOT="dist/pkg-root"
PKG_PATH="dist/rCodexPDF-$VERSION.pkg"
IDENTIFIER="com.rcodexpdf.app.pkg"
SIGN_IDENTITY="${INSTALLER_SIGN_IDENTITY:-}"

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "error: $APP_BUNDLE not found. Run Scripts/build-app.sh first." >&2
  exit 1
fi

rm -rf "$PKG_ROOT" "$PKG_PATH"
mkdir -p "$PKG_ROOT/Applications" "$PKG_ROOT/usr/local/bin"
cp -R "$APP_BUNDLE" "$PKG_ROOT/Applications/rCodexPDF.app"
cp "$APP_BUNDLE/Contents/Resources/bin/rcodexpdf" "$PKG_ROOT/usr/local/bin/rcodexpdf"
chmod 755 "$PKG_ROOT/usr/local/bin/rcodexpdf"

PKGBUILD_ARGS=(
  --root "$PKG_ROOT"
  --identifier "$IDENTIFIER"
  --version "$VERSION"
  --install-location /
  --scripts "$ROOT_DIR/Scripts/pkg-scripts"
)

if [[ -n "$SIGN_IDENTITY" ]]; then
  PKGBUILD_ARGS+=(--sign "$SIGN_IDENTITY")
fi

pkgbuild "${PKGBUILD_ARGS[@]}" "$PKG_PATH"

rm -rf "$PKG_ROOT"
echo "==> Built $PKG_PATH"
