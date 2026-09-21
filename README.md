# clipslot

**Per-session clipboard slots + clipboard history for parallel AI coding sessions.**

## The problem

You run several coding-agent sessions at once — Claude Code, Cursor, anything.
You ask session A to "copy the result to the clipboard". Before you paste it,
session B (or any app) also writes to the clipboard. The system clipboard is a
single global slot — last writer wins — so you paste the wrong thing into the
wrong thread.

## The fix — two layers

**Layer 1: cooperating agents use slots.** Agents save content into **named
slots** (`~/.clipslot/`), auto-named `<repo>@<branch>`, instead of writing to
the system clipboard. When **you** are about to paste, run `clipslot load`,
pick the right slot, and only then does it enter the real clipboard. Nothing
can clobber it between the pick and your Cmd+V. A bundled Claude Code skill
and a Cursor rule teach the agents to do this automatically.

**Layer 2: `clipslot watch` protects you from everything else.** A tiny
background watcher polls the system clipboard and snapshots **every change —
from any agent, any app, or your own Cmd+C** — into a `hist-*` slot (last 30
kept by default). No agent cooperation needed: even if something clobbers your
clipboard, every version is recoverable with `clipslot load`.

```bash
clipslot watch start    # run once (e.g. after login); stop / status likewise
```

Zero dependencies: one bash script. Works on macOS (`pbcopy`/`pbpaste`), Linux
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

# clipboard history (agent-independent safety net)
clipslot watch start                    # snapshot every clipboard change to hist-* slots
clipslot watch status
clipslot watch stop
```

### Slot naming

By default a slot is named `<repo>@<branch>`, falling back to the current
directory name outside a git repo. That makes "one slot per session" work
naturally when your parallel sessions live in different repos or branches
(the common case). Two sessions on the *same* repo and branch should pass
explicit names.

### Environment variables

| Variable                  | Meaning                                             |
|---------------------------|-----------------------------------------------------|
| `CLIPSLOT_DIR`            | Slot storage directory (default `~/.clipslot`)      |
| `CLIPSLOT_COPY_CMD`       | Override the clipboard write command (reads stdin), e.g. an OSC52 helper over SSH |
| `CLIPSLOT_PASTE_CMD`      | Override the clipboard read command (prints clipboard) |
| `CLIPSLOT_WATCH_INTERVAL` | Watcher poll interval in seconds (default 1)        |
| `CLIPSLOT_HISTORY_MAX`    | Max `hist-*` snapshots kept (default 30)            |

## Using it with each agent

**Claude Code** — `install.sh` installs [`skill/SKILL.md`](skill/SKILL.md) to
`~/.claude/skills/clipslot/`. Claude then automatically uses `clipslot copy`
instead of `pbcopy`, reports the slot name, and uses
`clipslot copy --also-system` only when you explicitly demand the system
clipboard.

**Cursor** — copy [`rules/clipslot.mdc`](rules/clipslot.mdc) into any
project's `.cursor/rules/` directory, or paste its body into
Cursor Settings → Rules to apply it globally.

**Any other agent** — paste the section from
[`rules/AGENTS-snippet.md`](rules/AGENTS-snippet.md) into the project's
`AGENTS.md` or the agent's instruction file.

**Agents you can't configure at all** — just run `clipslot watch start`.
They keep clobbering the system clipboard as usual, but every version is
snapshotted and recoverable with `clipslot load`.

## Limitations

- Text only (images and rich content are not handled).
- Rules/skills are advisory — agents follow them, but a stray tool writing
  straight to the system clipboard is outside their control. That's exactly
  what `clipslot watch` covers: the watcher needs no cooperation from anyone.
- The watcher polls (default every 1s); an extremely fast overwrite within
  one interval could be missed. In practice agent copies are seconds apart.

## License

MIT
