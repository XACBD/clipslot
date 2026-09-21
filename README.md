# clipslot

**Per-session clipboard slots for parallel AI coding sessions.**

## The problem

You run several Claude Code (or Cursor, or any agent) sessions at once. You ask
session A to "copy the result to the clipboard". Before you paste it, session B
also writes to the clipboard. The system clipboard is a single global slot —
last writer wins — so you paste the wrong thing into the wrong thread.

## The fix

`clipslot` splits "producing content" from "arming the clipboard":

- Agents save content into **named slots** (`~/.clipslot/`), auto-named
  `<repo>@<branch>`, instead of writing to the system clipboard.
- When **you** are about to paste, you run `clipslot load`, pick the right
  slot, and only then does it enter the real clipboard. Nothing can clobber
  it between the pick and your Cmd+V.

Zero dependencies: one bash script. Works on macOS (`pbcopy`), Linux
(`wl-copy` / `xclip` / `xsel`). `fzf` is used for the picker if installed,
with a numbered-menu fallback.

## Install

```bash
./install.sh
```

This installs:

1. the `clipslot` CLI into `~/.local/bin/`
2. a **Claude Code skill** into `~/.claude/skills/clipslot/` that teaches
   Claude to use `clipslot copy` instead of `pbcopy` automatically, and to
   tell you which slot it saved to.

## Usage

```bash
# save (what your agent runs — the skill makes Claude do this on its own)
git diff | clipslot copy                # slot auto-named e.g. myrepo@main
some-cmd | clipslot copy fix-login     # explicit slot name

# load (what you run right before pasting)
clipslot load                           # interactive picker (fzf or menu)
clipslot load myrepo@main               # directly by name

# inspect
clipslot list                           # all slots, newest first, with preview
clipslot show myrepo@main               # print a slot to stdout
clipslot rm fix-login
clipslot clear
```

### Slot naming

By default a slot is named `<repo>@<branch>`, falling back to the current
directory name outside a git repo. That makes "one slot per session" work
naturally when your parallel sessions live in different repos or branches
(the common case). Two sessions on the *same* repo and branch should pass
explicit names.

### Environment variables

| Variable            | Meaning                                             |
|---------------------|-----------------------------------------------------|
| `CLIPSLOT_DIR`      | Slot storage directory (default `~/.clipslot`)      |
| `CLIPSLOT_COPY_CMD` | Override the clipboard command (reads stdin), e.g. an OSC52 helper over SSH |

## How the Claude Code skill works

[`skill/SKILL.md`](skill/SKILL.md) instructs Claude:

- never pipe directly to `pbcopy`/`xclip`/`wl-copy`;
- use `clipslot copy` (with an explicit slot name if several sessions share a
  repo+branch);
- report the slot name so you know what to `clipslot load` later;
- if you explicitly demand the system clipboard, use
  `clipslot copy --also-system` so a recoverable copy still exists.

## Limitations

- Text only (images and rich content are not handled).
- The skill is advisory: Claude follows it, but a stray tool or app writing
  straight to the system clipboard is outside clipslot's control. The
  workflow is robust because *you* arm the clipboard last, right before
  pasting.

## License

MIT
