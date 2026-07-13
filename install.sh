#!/usr/bin/env bash
#
# rCodexPDF installer.
#
#   curl -fsSL https://raw.githubusercontent.com/rcodexpdf/rCodexPDF/main/install.sh | bash
#
# Installs rCodexPDF.app into /Applications and the `rcodexpdf` CLI onto your PATH.
# Safe to re-run: it detects an existing install and updates it in place.
#
# Flags (pass after `bash -s --` when piping from curl):
#   --from-source     Build from a local checkout instead of downloading a release.
#   --uninstall       Remove rCodexPDF (see also `rcodexpdf uninstall` once installed).
#   --version X.Y.Z   Install a specific released version instead of the latest.
#   --prefix DIR      Install the CLI into DIR instead of auto-detecting (default: /usr/local/bin
#                      or, if that isn't writable, ~/.local/bin).
set -euo pipefail

REPO="rcodexpdf/rCodexPDF"
APP_NAME="rCodexPDF.app"
APP_DEST="/Applications/$APP_NAME"

# ---------- output helpers ----------------------------------------------------------------
if [[ -t 1 ]] && [[ "${NO_COLOR:-}" == "" ]]; then
  C_RESET=$'\033[0m'; C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_BLUE=$'\033[34m'; C_BOLD=$'\033[1m'
else
  C_RESET=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_BOLD=""
fi
info()    { echo "${C_BLUE}ℹ${C_RESET} $*"; }
success() { echo "${C_GREEN}✔${C_RESET} $*"; }
warn()    { echo "${C_YELLOW}⚠${C_RESET} $*"; }
error()   { echo "${C_RED}✖${C_RESET} $*" >&2; }
bold()    { echo "${C_BOLD}$*${C_RESET}"; }

# ---------- argument parsing ---------------------------------------------------------------
FROM_SOURCE=0
DO_UNINSTALL=0
REQUESTED_VERSION=""
CLI_PREFIX=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from-source) FROM_SOURCE=1; shift ;;
    --uninstall) DO_UNINSTALL=1; shift ;;
    --version) REQUESTED_VERSION="$2"; shift 2 ;;
    --prefix) CLI_PREFIX="$2"; shift 2 ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) error "Unknown option: $1"; exit 1 ;;
  esac
done

# ---------- platform checks ------------------------------------------------------------------
if [[ "$(uname -s)" != "Darwin" ]]; then
  error "rCodexPDF only supports macOS."
  exit 1
fi

ARCH="$(uname -m)"
case "$ARCH" in
  arm64) info "Detected Apple Silicon (arm64)." ;;
  x86_64) info "Detected Intel Mac (x86_64)." ;;
  *) warn "Unrecognized architecture '$ARCH'; continuing anyway." ;;
esac

MACOS_VERSION="$(sw_vers -productVersion 2>/dev/null || echo "unknown")"
info "macOS $MACOS_VERSION"

# ---------- uninstall -------------------------------------------------------------------------
if [[ "$DO_UNINSTALL" == "1" ]]; then
  bold "Uninstalling rCodexPDF"
  removed=0
  if [[ -d "$APP_DEST" ]]; then
    rm -rf "$APP_DEST"
    success "Removed $APP_DEST"
    removed=1
  fi
  for cli in /usr/local/bin/rcodexpdf "$HOME/.local/bin/rcodexpdf"; do
    if [[ -e "$cli" ]]; then
      rm -f "$cli"
      success "Removed $cli"
      removed=1
    fi
  done
  for comp in /usr/local/share/zsh/site-functions/_rcodexpdf /usr/local/etc/bash_completion.d/rcodexpdf "$HOME/.zsh/completions/_rcodexpdf"; do
    [[ -e "$comp" ]] && rm -f "$comp" && removed=1
  done
  if [[ "$removed" == "0" ]]; then
    warn "Nothing found to remove."
  else
    success "Uninstall complete. Application data and Keychain entries were left in place;"
    echo "  run 'rcodexpdf uninstall --purge' before removing the CLI to also delete those."
  fi
  exit 0
fi

# ---------- dependency checks -----------------------------------------------------------------
bold "Checking dependencies"
if ! xcode-select -p >/dev/null 2>&1; then
  warn "Xcode Command Line Tools not found. The code editor's compiler features need per-language"
  warn "toolchains (clang/clang++ ship with Command Line Tools). Install with: xcode-select --install"
else
  success "Command Line Tools found."
fi
if ! command -v curl >/dev/null 2>&1; then
  error "curl is required but not found."
  exit 1
fi
success "curl found."

# ---------- resolve version ---------------------------------------------------------------------
resolve_latest_version() {
  curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
    | grep '"tag_name"' \
    | head -1 \
    | sed -E 's/.*"v?([0-9]+\.[0-9]+\.[0-9]+)".*/\1/'
}

INSTALL_VERSION="$REQUESTED_VERSION"
if [[ "$FROM_SOURCE" == "0" && -z "$INSTALL_VERSION" ]]; then
  bold "Checking latest release"
  INSTALL_VERSION="$(resolve_latest_version || true)"
  if [[ -z "$INSTALL_VERSION" ]]; then
    warn "Could not reach GitHub releases API. Falling back to --from-source."
    FROM_SOURCE=1
  else
    info "Latest version: $INSTALL_VERSION"
  fi
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

# ---------- install from a release ZIP, or build from source -----------------------------------
if [[ "$FROM_SOURCE" == "1" ]]; then
  bold "Building from source"
  SRC_DIR="$WORK_DIR/src"
  if [[ -f "./Package.swift" && -d "./Sources/RCodexPDFApp" ]]; then
    info "Using local checkout at $(pwd)"
    SRC_DIR="$(pwd)"
  else
    if ! command -v git >/dev/null 2>&1; then
      error "git is required to build from source."
      exit 1
    fi
    info "Cloning $REPO…"
    git clone --depth 1 "https://github.com/$REPO.git" "$SRC_DIR"
  fi
  ( cd "$SRC_DIR" && ./Scripts/build-app.sh )
  APP_BUILD_PATH="$SRC_DIR/dist/$APP_NAME"
else
  bold "Downloading rCodexPDF $INSTALL_VERSION"
  ZIP_URL="https://github.com/$REPO/releases/download/v$INSTALL_VERSION/rCodexPDF-$INSTALL_VERSION-macOS.zip"
  ZIP_PATH="$WORK_DIR/rCodexPDF.zip"
  if ! curl -fL --progress-bar -o "$ZIP_PATH" "$ZIP_URL"; then
    error "Download failed: $ZIP_URL"
    error "If this repository has no releases yet, try: install.sh --from-source"
    exit 1
  fi
  success "Downloaded."
  info "Unpacking…"
  ditto -x -k "$ZIP_PATH" "$WORK_DIR/unzipped"
  APP_BUILD_PATH="$WORK_DIR/unzipped/$APP_NAME"
fi

if [[ ! -d "$APP_BUILD_PATH" ]]; then
  error "Expected app bundle not found at $APP_BUILD_PATH"
  exit 1
fi

# ---------- install the app ---------------------------------------------------------------------
bold "Installing application"
if [[ -d "$APP_DEST" ]]; then
  info "Existing install found; replacing it."
  rm -rf "$APP_DEST"
fi

if [[ -w /Applications ]]; then
  cp -R "$APP_BUILD_PATH" "$APP_DEST"
else
  info "Requesting administrator privileges to write to /Applications…"
  sudo cp -R "$APP_BUILD_PATH" "$APP_DEST"
fi
xattr -dr com.apple.quarantine "$APP_DEST" 2>/dev/null || true
success "Installed $APP_DEST"

# ---------- install the CLI ----------------------------------------------------------------------
bold "Installing CLI"
CLI_SOURCE="$APP_DEST/Contents/Resources/bin/rcodexpdf"
if [[ ! -f "$CLI_SOURCE" ]]; then
  error "CLI binary not found inside app bundle."
  exit 1
fi

if [[ -z "$CLI_PREFIX" ]]; then
  if [[ -w /usr/local/bin || -w /usr/local ]]; then
    CLI_PREFIX="/usr/local/bin"
  else
    CLI_PREFIX="$HOME/.local/bin"
  fi
fi
mkdir -p "$CLI_PREFIX"
if [[ -w "$CLI_PREFIX" ]]; then
  cp "$CLI_SOURCE" "$CLI_PREFIX/rcodexpdf"
else
  sudo cp "$CLI_SOURCE" "$CLI_PREFIX/rcodexpdf"
fi
chmod +x "$CLI_PREFIX/rcodexpdf" 2>/dev/null || sudo chmod +x "$CLI_PREFIX/rcodexpdf"
success "Installed $CLI_PREFIX/rcodexpdf"

# ---------- PATH setup ---------------------------------------------------------------------------
if ! command -v rcodexpdf >/dev/null 2>&1 || [[ ":$PATH:" != *":$CLI_PREFIX:"* ]]; then
  bold "Updating PATH"
  SHELL_RC=""
  case "$(basename "${SHELL:-/bin/zsh}")" in
    zsh) SHELL_RC="$HOME/.zshrc" ;;
    bash) SHELL_RC="$HOME/.bash_profile" ;;
    *) SHELL_RC="$HOME/.profile" ;;
  esac
  EXPORT_LINE="export PATH=\"$CLI_PREFIX:\$PATH\""
  if [[ -f "$SHELL_RC" ]] && grep -qF "$CLI_PREFIX" "$SHELL_RC" 2>/dev/null; then
    info "$SHELL_RC already references $CLI_PREFIX"
  else
    { echo ""; echo "# Added by rCodexPDF installer"; echo "$EXPORT_LINE"; } >> "$SHELL_RC"
    success "Added $CLI_PREFIX to PATH in $SHELL_RC"
    warn "Run 'source $SHELL_RC' or open a new terminal for this to take effect."
  fi
fi

# ---------- shell completions ---------------------------------------------------------------------
bold "Installing shell completions"
if [[ -w /usr/local/share/zsh/site-functions ]] || mkdir -p /usr/local/share/zsh/site-functions 2>/dev/null; then
  "$CLI_PREFIX/rcodexpdf" --generate-completion-script zsh > /usr/local/share/zsh/site-functions/_rcodexpdf 2>/dev/null \
    && success "zsh completion installed." || warn "Could not install zsh completion (non-fatal)."
fi
if mkdir -p "$HOME/.bash_completion.d" 2>/dev/null; then
  "$CLI_PREFIX/rcodexpdf" --generate-completion-script bash > "$HOME/.bash_completion.d/rcodexpdf" 2>/dev/null \
    && success "bash completion installed to ~/.bash_completion.d/rcodexpdf." || true
fi

echo ""
success "$(bold "rCodexPDF is installed!")"
echo "  Launch the app:  open -a rCodexPDF"
echo "  Or use the CLI:  rcodexpdf --help"
echo ""
