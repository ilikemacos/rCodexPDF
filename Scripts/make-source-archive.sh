#!/usr/bin/env bash
# Produces a clean source tarball straight from git (respects .gitignore), for the
# "source archive" release artifact.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

VERSION="$(grep -o '"[0-9]*\.[0-9]*\.[0-9]*"' Sources/rcodexpdf/Support/Version.swift | tr -d '"' | head -1)"
OUT="dist/rCodexPDF-$VERSION-source.tar.gz"

mkdir -p dist
git archive --format=tar.gz --prefix="rCodexPDF-$VERSION/" -o "$OUT" HEAD
echo "==> Built $OUT"
