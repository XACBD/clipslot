import {
  Action,
  ActionPanel,
  Alert,
  Color,
  Icon,
  List,
  Toast,
  confirmAlert,
  showToast,
} from "@raycast/api";
import * as fs from "fs";
import * as path from "path";
import { homedir } from "os";
import { useCallback, useEffect, useState } from "react";

const SLOT_DIR = process.env.CLIPSLOT_DIR ?? path.join(homedir(), ".clipslot");
const PREVIEW_CAP = 100_000; // chars shown in the detail pane

interface Slot {
  name: string;
  content: string;
  truncated: boolean;
  mtimeMs: number;
  size: number;
  isHistory: boolean;
}

function readSlots(): Slot[] {
  let entries: string[];
  try {
    entries = fs.readdirSync(SLOT_DIR);
  } catch {
    return []; // directory doesn't exist yet — nothing saved
  }
  const slots: Slot[] = [];
  for (const name of entries) {
    if (name.startsWith(".")) continue; // .watch.pid etc.
    const file = path.join(SLOT_DIR, name);
    let stat: fs.Stats;
    try {
      stat = fs.statSync(file);
    } catch {
      continue;
    }
    if (!stat.isFile()) continue;
    let content = "";
    try {
      content = fs.readFileSync(file, "utf8");
    } catch {
      continue;
    }
    slots.push({
      name,
      content: content.slice(0, PREVIEW_CAP),
      truncated: content.length > PREVIEW_CAP,
      mtimeMs: stat.mtimeMs,
      size: stat.size,
      isHistory: name.startsWith("hist-"),
    });
  }
  return slots.sort((a, b) => b.mtimeMs - a.mtimeMs);
}

function relativeAge(mtimeMs: number): string {
  const s = Math.max(0, Math.round((Date.now() - mtimeMs) / 1000));
  if (s < 60) return `${s}s ago`;
  if (s < 3600) return `${Math.floor(s / 60)}m ago`;
  if (s < 86400) return `${Math.floor(s / 3600)}h ago`;
  return `${Math.floor(s / 86400)}d ago`;
}

function humanSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

function detailMarkdown(slot: Slot): string {
  const fence = "`````";
  const note = slot.truncated ? "\n\n*(preview truncated)*" : "";
  return `${fence}\n${slot.content}\n${fence}${note}`;
}

function SlotItem(props: { slot: Slot; onDeleted: () => void }) {
  const { slot, onDeleted } = props;

  async function deleteSlot() {
    const ok = await confirmAlert({
      title: `Delete slot “${slot.name}”?`,
      message: "The saved content will be removed. This cannot be undone.",
      primaryAction: { title: "Delete", style: Alert.ActionStyle.Destructive },
    });
    if (!ok) return;
    try {
      fs.unlinkSync(path.join(SLOT_DIR, slot.name));
      await showToast({ style: Toast.Style.Success, title: `Deleted ${slot.name}` });
      onDeleted();
    } catch (e) {
      await showToast({
        style: Toast.Style.Failure,
        title: "Could not delete slot",
        message: String(e),
      });
    }
  }

  const firstLine = slot.content.split("\n", 1)[0].trim();

  return (
    <List.Item
      key={slot.name}
      title={slot.name}
      subtitle={firstLine.length > 48 ? `${firstLine.slice(0, 48)}…` : firstLine}
      icon={
        slot.isHistory
          ? { source: Icon.Clock, tintColor: Color.SecondaryText }
          : { source: Icon.Clipboard, tintColor: Color.Purple }
      }
      accessories={[{ text: humanSize(slot.size) }, { text: relativeAge(slot.mtimeMs) }]}
      detail={<List.Item.Detail markdown={detailMarkdown(slot)} />}
      actions={
        <ActionPanel>
          <Action.Paste title="Paste to Active App" content={slot.content} />
          <Action.CopyToClipboard title="Load into Clipboard" content={slot.content} />
          <Action
            title="Delete Slot"
            icon={Icon.Trash}
            style={Action.Style.Destructive}
            shortcut={{ modifiers: ["ctrl"], key: "x" }}
            onAction={deleteSlot}
          />
        </ActionPanel>
      }
    />
  );
}

export default function Command() {
  const [slots, setSlots] = useState<Slot[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const refresh = useCallback(() => {
    setSlots(readSlots());
    setIsLoading(false);
  }, []);

  useEffect(refresh, [refresh]);

  const sessionSlots = slots.filter((s) => !s.isHistory);
  const historySlots = slots.filter((s) => s.isHistory);

  return (
    <List
      isLoading={isLoading}
      isShowingDetail={slots.length > 0}
      searchBarPlaceholder="Search slots by name or first line…"
    >
      {slots.length === 0 && (
        <List.EmptyView
          icon={Icon.Clipboard}
          title="No slots yet"
          description={`Save one with:  <cmd> | clipslot copy\nOr start the history watcher:  clipslot watch install`}
        />
      )}
      <List.Section title="Session Slots" subtitle={`${sessionSlots.length}`}>
        {sessionSlots.map((slot) => (
          <SlotItem key={slot.name} slot={slot} onDeleted={refresh} />
        ))}
      </List.Section>
      <List.Section title="Clipboard History" subtitle={`${historySlots.length}`}>
        {historySlots.map((slot) => (
          <SlotItem key={slot.name} slot={slot} onDeleted={refresh} />
        ))}
      </List.Section>
    </List>
  );
}
