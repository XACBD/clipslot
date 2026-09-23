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

# --- Codex CLI global instructions ---
if [ -d "$HOME/.codex" ]; then
  codex_agents="$HOME/.codex/AGENTS.md"
  if grep -q "clipslot" "$codex_agents" 2>/dev/null; then
    echo "Codex clipboard policy already present -> $codex_agents"
  else
    cat >> "$codex_agents" <<'EOF'

## Clipboard policy (clipslot)

Never pipe content directly to `pbcopy`, `xclip`, `wl-copy`, or `xsel` — the
user runs parallel agent sessions and the global clipboard gets clobbered.
When asked to copy something to the clipboard, run:

```bash
<command producing content> | clipslot copy
```

The slot is auto-named `<repo>@<branch>`; pass an explicit name
(`clipslot copy <task-name>`) if several sessions share a repo+branch.
After saving, tell the user the slot name and that `clipslot load` puts it
into the real clipboard when they are ready to paste. If the user explicitly
wants the system clipboard immediately, use `clipslot copy --also-system`.
EOF
    echo "installed Codex clipboard policy -> $codex_agents"
  fi
fi

echo
echo "Done. Try it:"
echo "  echo hello | clipslot copy demo && clipslot load demo"
echo
echo "Recommended: start the clipboard-history watcher (agent-independent safety net):"
echo "  clipslot watch start"
echo
echo "Using Cursor or another agent? See rules/clipslot.mdc (Cursor rule) and"
echo "rules/AGENTS-snippet.md (for AGENTS.md) in this directory."
