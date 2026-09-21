# clipslot snippet for AGENTS.md

Paste this section into any project's `AGENTS.md` (or your agent's global
instruction file) to make coding agents use clipslot. Works with any agent
that reads AGENTS.md (Cursor, Codex, Claude Code, etc.).

---

## Clipboard policy

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
