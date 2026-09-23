<div align="center">

<img src="assets/banner.svg" alt="clipslot — one clipboard, many agents" width="680">

<br>
<br>

[![CI](https://github.com/XACBD/clipslot/actions/workflows/ci.yml/badge.svg)](https://github.com/XACBD/clipslot/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey)](#install)
[![Made with Bash](https://img.shields.io/badge/made%20with-bash-1f425f.svg)](clipslot)
[![Zero dependencies](https://img.shields.io/badge/dependencies-zero-brightgreen)](clipslot)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](#contributing)

**Per-session clipboard slots + clipboard history for parallel AI coding sessions.**

</div>

---

You run several coding agents at once — Claude Code, Cursor, anything.
You ask session A to *"copy the result to the clipboard"*. Before you paste,
session B writes to the clipboard too. The system clipboard is one global
slot, last writer wins — and you paste the wrong thing into the wrong thread.

```text
without clipslot                        with clipslot

session A ──┐                           session A ──▶ slot repo-a@main
session B ──┼──▶ [ clipboard ] ◀── 💥   session B ──▶ slot repo-b@fix
session C ──┘    last writer wins       session C ──▶ slot repo-c@main
                                                          │
you: Cmd+V 🎲                           you: clipslot load ──▶ [ clipboard ] ──▶ Cmd+V ✅
```

## How it works

**① Agents write to slots, not the clipboard.** With the bundled Claude Code
skill / Cursor rule installed, agents run `clipslot copy` instead of `pbcopy`.
Content lands in a named slot (auto-named `repo@branch`) under `~/.clipslot/`.
Nothing touches the system clipboard, so sessions can't clobber each other.

**② You arm the clipboard last.** Right before pasting, run `clipslot load`,
pick the slot (fzf picker if installed, numbered menu otherwise) — only then
does it enter the real clipboard.

**③ A watcher covers everything else.** `clipslot watch start` snapshots
*every* clipboard change — any agent, any app, your own Cmd+C — into `hist-*`
slots (deduped, last 30 kept). Zero cooperation needed; clobbered content is
always recoverable.

## Install

**macOS, one command** (clones the repo, installs the CLI + Claude Code skill,
registers the login watcher, prepares the Raycast extension):

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/XACBD/clipslot/main/setup-mac.sh)"
```

Or manually:

```bash
git clone https://github.com/XACBD/clipslot.git
cd clipslot && ./install.sh
```

This installs the `clipslot` CLI to `~/.local/bin` and the Claude Code skill
to `~/.claude/skills/clipslot/`. One bash script, zero dependencies.
macOS (`pbcopy`/`pbpaste`) and Linux (`wl-copy`/`xclip`/`xsel`) supported.

## Usage

```bash
# agents save (the skill/rule makes them do this automatically)
git diff | clipslot copy              # slot auto-named, e.g. myrepo@main
some-cmd | clipslot copy fix-login    # explicit slot name

# you load, right before pasting
clipslot load                         # interactive picker
clipslot load myrepo@main             # directly by name
clipslot load -1                      # most recent slot, no picker

# clipboard history — the agent-independent safety net
clipslot watch install                # start at login (launchd / systemd)
clipslot watch start                  # ...or just for this session
```

| Command                  | What it does                                      |
|--------------------------|---------------------------------------------------|
| `... \| clipslot copy [name]` | Save stdin to a slot (never touches the clipboard) |
| `clipslot copy -s [name]`| …and *also* copy to the system clipboard          |
| `clipslot load [name]`   | Put a slot into the system clipboard              |
| `clipslot load -1`       | Load the most recent slot, no picker              |
| `clipslot list`          | All slots, newest first, with size / age / preview|
| `clipslot show [name]`   | Print a slot to stdout                            |
| `clipslot rm` / `clear`  | Remove one / all slots                            |
| `clipslot watch start\|stop\|status` | Manage the clipboard-history watcher  |
| `clipslot watch install\|uninstall` | Register/remove the watcher as a login service (launchd / systemd) |

## Raycast extension (macOS) — the fastest way to paste

The [`raycast/`](raycast/) extension removes the terminal from the loop
entirely: hit your Raycast hotkey, type a few letters, **press Enter and the
slot is pasted straight into the app you came from** — no `clipslot load`,
no Cmd+V.

- Session slots and clipboard history in separate sections, newest first
- Full content preview pane, search by name or first line
- Enter = paste to active app · Cmd+Enter = load into clipboard · Ctrl+X = delete

Install (requires [Raycast](https://raycast.com) and Node.js):

```bash
cd clipslot/raycast
npm install && npm run dev   # installs the extension into Raycast
```

After the first `npm run dev`, the extension stays in Raycast — assign a
hotkey to "Search Clipboard Slots" in Raycast settings and you're done.

### No Raycast? Native picker instead

`clipslot load --gui` opens a built-in macOS list dialog (no third-party
apps). To give it a global hotkey with only stock macOS tools: open the
**Shortcuts** app → new shortcut → "Run Shell Script" with
`~/.local/bin/clipslot load --gui` → assign a keyboard shortcut in the
shortcut's settings. Pick a slot, then Cmd+V wherever you are.

## Agent integrations

| Agent            | Setup                                                                 |
|------------------|-----------------------------------------------------------------------|
| **Claude Code**  | Installed automatically by `install.sh` ([`skill/SKILL.md`](skill/SKILL.md)) |
| **Codex CLI**    | Installed automatically by `install.sh` (appends the policy to `~/.codex/AGENTS.md` if Codex is present) |
| **Cursor**       | Drop [`rules/clipslot.mdc`](rules/clipslot.mdc) into `.cursor/rules/`, or paste into *Settings → Rules* for all projects |
| **Anything that reads `AGENTS.md`** | Paste the section from [`rules/AGENTS-snippet.md`](rules/AGENTS-snippet.md) |
| **Agents you can't configure** | Just run `clipslot watch start` — every clipboard write gets snapshotted anyway |

## Configuration

| Variable                  | Default        | Meaning                                  |
|---------------------------|----------------|------------------------------------------|
| `CLIPSLOT_DIR`            | `~/.clipslot`  | Slot storage directory                   |
| `CLIPSLOT_HISTORY_MAX`    | `30`           | Max `hist-*` snapshots kept              |
| `CLIPSLOT_WATCH_INTERVAL` | `1`            | Watcher poll interval (seconds)          |
| `CLIPSLOT_MAX_BYTES`      | `1000000`      | Watcher skips clipboard payloads larger than this |
| `CLIPSLOT_COPY_CMD`       | auto           | Override clipboard **write** command (reads stdin) — e.g. an OSC52 helper over SSH |
| `CLIPSLOT_PASTE_CMD`      | auto           | Override clipboard **read** command      |

## FAQ

**How is this different from Maccy / Raycast clipboard history?**
Those solve recovery (like `clipslot watch`). clipslot's core is the other
half: a *protocol for agents* — slots named per repo/branch, plus skill/rule
files that teach Claude Code and Cursor to stop fighting over the clipboard
in the first place, and to tell you which slot they saved to.

**Two sessions on the same repo and branch?**
They'd share an auto-named slot — pass explicit names (`clipslot copy
task-a`). The skill/rule files instruct agents to do this.

**What about images?**
Text only, by design. Rich content is out of scope for one bash script.

**Can a rogue write slip past the watcher?**
The watcher polls (1s default) — two overwrites within one interval could
lose the first. In practice agent copies are seconds apart.

## Contributing

It's ~350 lines of bash. Issues and PRs welcome — please keep the
zero-dependency promise.

## License

[MIT](LICENSE)
