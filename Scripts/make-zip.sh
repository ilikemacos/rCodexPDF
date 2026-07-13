#!/usr/bin/env bash
# Zips dist/rCodexPDF.app for the "ZIP release" distribution channel.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

VERSION="$(grep -o '"[0-9]*\.[0-9]*\.[0-9]*"' Sources/rcodexpdf/Support/Version.swift | tr -d '"' | head -1)"
APP_BUNDLE="dist/rCodexPDF.app"
ZIP_PATH="dist/rCodexPDF-$VERSION-macOS.zip"

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "error: $APP_BUNDLE not found. Run Scripts/build-app.sh first." >&2
  exit 1
fi

rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_BUNDLE" "$ZIP_PATH"
echo "==> Built $ZIP_PATH"
