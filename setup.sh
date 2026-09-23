#!/usr/bin/env bash
# One-command setup (macOS & Linux):
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/XACBD/clipslot/main/setup.sh)"
# Clones/updates the repo, installs the CLI + agent integrations, registers
# the clipboard watcher at login, and (macOS + Raycast) prepares the extension.
set -euo pipefail

REPO_DIR="${CLIPSLOT_REPO_DIR:-$HOME/clipslot}"
REPO_URL="${CLIPSLOT_REPO_URL:-https://github.com/XACBD/clipslot.git}"
REPO_URL_SSH="git@github.com:XACBD/clipslot.git"
OS=$(uname)

step() { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }

step "Getting the code ($REPO_DIR)"
if [ -d "$REPO_DIR/.git" ]; then
  git -C "$REPO_DIR" pull --ff-only || {
    echo "Pull failed (network?). Continuing with the existing checkout."
  }
else
  if ! git clone "$REPO_URL" "$REPO_DIR"; then
    echo "HTTPS clone failed (blocked/reset network?) — trying SSH..."
    git clone "$REPO_URL_SSH" "$REPO_DIR" || {
      echo ""
      echo "SSH also failed. Two options:"
      echo "  1. Enable your VPN/proxy and re-run this command."
      echo "  2. Route SSH over port 443: add to ~/.ssh/config:"
      echo "       Host github.com"
      echo "         HostName ssh.github.com"
      echo "         Port 443"
      echo "         User git"
      echo "     then re-run this command."
      exit 1
    }
  fi
fi

step "Installing CLI + agent integrations (Claude Code skill, Codex policy)"
"$REPO_DIR/install.sh"

CLIPSLOT_BIN="${CLIPSLOT_BIN_DIR:-$HOME/.local/bin}/clipslot"

step "Registering the clipboard watcher (starts at login)"
if ! "$CLIPSLOT_BIN" watch install; then
  echo "Autostart registration failed (no launchd/systemd session?)."
  echo "Start it manually per session with: clipslot watch start"
fi

if [ "$OS" = "Darwin" ]; then
  step "Raycast extension (optional)"
  if [ -d "/Applications/Raycast.app" ] || [ -d "$HOME/Applications/Raycast.app" ]; then
    if command -v npm >/dev/null 2>&1; then
      (cd "$REPO_DIR/raycast" && npm install --no-fund --no-audit)
      cat <<'EOF'

Raycast extension is prepared. Two manual steps remain (they need the UI):
  1. Run:  cd ~/clipslot/raycast && npm run dev
     Wait until Raycast loads the extension, then press Ctrl+C.
  2. Raycast Settings -> Extensions -> "Search Clipboard Slots" -> assign a hotkey.

No Raycast? Use the native dialog instead:  clipslot load --gui
EOF
    else
      echo "npm not found — skipping. For the Raycast extension install Node.js, then:"
      echo "  cd $REPO_DIR/raycast && npm install && npm run dev"
    fi
  else
    echo "Raycast not installed — skipping. Native picker works without it:  clipslot load --gui"
  fi
fi

step "Quick self-test"
printf 'clipslot setup works' | "$CLIPSLOT_BIN" copy setup-test
"$CLIPSLOT_BIN" show setup-test >/dev/null
"$CLIPSLOT_BIN" rm setup-test
"$CLIPSLOT_BIN" version

printf '\n\033[1;32mDone. Copy something twice, then run: clipslot load\033[0m\n'
