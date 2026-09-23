#!/usr/bin/env bash
# End-to-end smoke test using a fake clipboard (no display server needed).
set -euo pipefail

cd "$(dirname "$0")/.."
CLIPSLOT=./clipslot

export CLIPSLOT_DIR
CLIPSLOT_DIR=$(mktemp -d)
FAKECLIP=$(mktemp)
export CLIPSLOT_COPY_CMD="cat > $FAKECLIP"
export CLIPSLOT_PASTE_CMD="cat $FAKECLIP"
export CLIPSLOT_WATCH_INTERVAL=0.2
export CLIPSLOT_HISTORY_MAX=3

trap 'rm -rf "$CLIPSLOT_DIR" "$FAKECLIP"' EXIT

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "ok: $1"; }

# --- copy / show / load by name ---
printf 'hello world' | $CLIPSLOT copy demo
[ "$($CLIPSLOT show demo)" = "hello world" ] || fail "show returns saved content"
pass "copy + show"

$CLIPSLOT load demo
[ "$(cat "$FAKECLIP")" = "hello world" ] || fail "load puts slot into clipboard"
pass "load by name"

# --- copy does NOT touch the clipboard ---
printf 'sneaky' | $CLIPSLOT copy other
[ "$(cat "$FAKECLIP")" = "hello world" ] || fail "copy must not touch clipboard"
pass "copy isolation"

# --- copy --also-system does ---
printf 'urgent' | $CLIPSLOT copy -s urgent
[ "$(cat "$FAKECLIP")" = "urgent" ] || fail "--also-system writes clipboard"
pass "copy --also-system"

# --- load --latest picks newest slot ---
sleep 1.1  # mtime granularity is 1s on some filesystems
printf 'newest' | $CLIPSLOT copy fresh
$CLIPSLOT load --latest
[ "$(cat "$FAKECLIP")" = "newest" ] || fail "--latest loads newest slot"
pass "load --latest"

# --- list shows slots ---
list_out=$($CLIPSLOT list)
printf '%s' "$list_out" | grep -q fresh || fail "list mentions slot"
pass "list"

# --- rm / clear ---
$CLIPSLOT rm urgent
$CLIPSLOT show urgent 2>/dev/null && fail "rm removes slot"
$CLIPSLOT clear
[ -z "$($CLIPSLOT list | grep -v 'no slots' || true)" ] || fail "clear empties store"
pass "rm + clear"

# --- watcher: snapshots, dedupe, pruning, size guard ---
$CLIPSLOT watch start
sleep 0.5
for i in 1 2 3 4 5; do printf 'clip-%s' "$i" > "$FAKECLIP"; sleep 0.5; done
printf 'clip-5' > "$FAKECLIP"; sleep 0.5   # duplicate, must not add a slot
head -c 2000000 /dev/zero | tr '\0' 'x' > "$FAKECLIP"; sleep 0.5  # oversized, skipped
$CLIPSLOT watch stop

hist_count=$(find "$CLIPSLOT_DIR" -name 'hist-*' | wc -l)
[ "$hist_count" -eq 3 ] || fail "expected 3 hist slots (prune to CLIPSLOT_HISTORY_MAX), got $hist_count"
grep -rq 'clip-5' "$CLIPSLOT_DIR" || fail "newest snapshot kept"
grep -rql 'xxxxx' "$CLIPSLOT_DIR" && fail "oversized payload must be skipped"
pass "watcher: snapshot + dedupe + prune + size guard"

# --- version ---
$CLIPSLOT version | grep -q '^clipslot 0\.' || fail "version prints"
pass "version"

echo "ALL SMOKE TESTS PASSED"
