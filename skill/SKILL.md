---
name: clipslot
description: Save clipboard content to a per-session slot instead of the shared system clipboard, so parallel Claude Code sessions don't overwrite each other. Use whenever the user asks to copy something to the clipboard (pbcopy, xclip, "copy this", "放到剪切板").
---

# clipslot — don't clobber the shared clipboard

The user runs multiple Claude Code sessions in parallel. The system clipboard
(`pbcopy` / `xclip`) is global: if you write to it directly, another session
may overwrite it before the user pastes, and vice versa. **Never pipe content
directly to `pbcopy`, `xclip`, `xsel`, or `wl-copy`.**

## What to do instead

When the user asks you to copy something to the clipboard, save it to a
clipslot slot:

```bash
<command that produces the content> | clipslot copy
```

or for content you generated yourself:

```bash
clipslot copy <<'EOF'
...content...
EOF
```

`clipslot copy` names the slot automatically as `<repo>@<branch>` (or the
current directory name outside a git repo). If the user is likely running
several sessions on the same repo and branch, pass an explicit name that
identifies this task, e.g. `clipslot copy myrepo-fix-login`.

## What to tell the user

After saving, always tell the user, in one short line:

1. the slot name (it is printed by `clipslot copy` on stderr), and
2. that they can load it into the real clipboard with `clipslot load` —
   which shows a picker — or `clipslot load <slot-name>` directly.

Example: "已存入槽位 `myrepo@main`，要贴的时候运行 `clipslot load` 选它即可。"

## Exceptions

- If the user *explicitly* insists on the system clipboard right now, use
  `clipslot copy --also-system` (saves the slot AND sets the system
  clipboard), so there is still a recoverable copy if it gets clobbered.
- If `clipslot` is not installed (command not found), fall back to the
  system clipboard and suggest installing clipslot.
