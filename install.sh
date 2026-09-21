#!/usr/bin/env bash
# Installs the clipslot CLI and the Claude Code skill.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)

# --- CLI ---
bin_dir="${CLIPSLOT_BIN_DIR:-$HOME/.local/bin}"
mkdir -p "$bin_dir"
install -m 0755 "$here/clipslot" "$bin_dir/clipslot"
echo "installed CLI -> $bin_dir/clipslot"

case ":$PATH:" in
  *":$bin_dir:"*) ;;
  *) echo "NOTE: $bin_dir is not on your PATH. Add this to your shell rc:"
     echo "  export PATH=\"$bin_dir:\$PATH\"" ;;
esac

# --- Claude Code skill ---
skill_dir="$HOME/.claude/skills/clipslot"
mkdir -p "$skill_dir"
install -m 0644 "$here/skill/SKILL.md" "$skill_dir/SKILL.md"
echo "installed Claude Code skill -> $skill_dir/SKILL.md"

echo
echo "Done. Try it:"
echo "  echo hello | clipslot copy demo && clipslot load demo"
