#!/usr/bin/env bash
# One-command setup for macOS:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/XACBD/clipslot/main/setup-mac.sh)"
# Clones/updates the repo, installs the CLI + Claude Code skill, registers
# the clipboard watcher at login, and prepares the Raycast extension.
set -euo pipefail

REPO_DIR="${CLIPSLOT_REPO_DIR:-$HOME/clipslot}"
REPO_URL="https://github.com/XACBD/clipslot.git"

step() { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }

step "Getting the code ($REPO_DIR)"
if [ -d "$REPO_DIR/.git" ]; then
  git -C "$REPO_DIR" pull --ff-only
else
  git clone "$REPO_URL" "$REPO_DIR"
fi

step "Installing CLI + Claude Code skill"
"$REPO_DIR/install.sh"

CLIPSLOT_BIN="${CLIPSLOT_BIN_DIR:-$HOME/.local/bin}/clipslot"

step "Registering the clipboard watcher (starts at login)"
"$CLIPSLOT_BIN" watch install

step "Raycast extension"
if [ -d "/Applications/Raycast.app" ] || [ -d "$HOME/Applications/Raycast.app" ]; then
  if command -v npm >/dev/null 2>&1; then
    (cd "$REPO_DIR/raycast" && npm install --no-fund --no-audit)
    cat <<'EOF'

Almost done — two manual steps remain (they need the Raycast UI):

  1. Run:   cd ~/clipslot/raycast && npm run dev
     Wait until Raycast shows the extension loaded, then press Ctrl+C.
     The extension stays installed.

  2. Raycast Settings -> Extensions -> "Search Clipboard Slots"
     -> assign a hotkey (suggestion: Option+V).
EOF
  else
    echo "npm not found — install Node.js (https://nodejs.org), then run:"
    echo "  cd $REPO_DIR/raycast && npm install && npm run dev"
  fi
else
  echo "Raycast not found — skipping the extension."
  echo "Get it at https://raycast.com, then run: cd $REPO_DIR/raycast && npm install && npm run dev"
fi

step "Quick self-test"
printf 'clipslot setup works' | "$CLIPSLOT_BIN" copy setup-test
"$CLIPSLOT_BIN" list
"$CLIPSLOT_BIN" rm setup-test

printf '\n\033[1;32mDone. Copy something twice, then run: clipslot load\033[0m\n'
