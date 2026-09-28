pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

// Clipboard history (cliphist) and inserting symbols, with
// paste-into-the-previous-window.
//
// History is recorded by `wl-paste --watch cliphist store` (started from the
// compositor config). Opening remembers the focused window; picking an entry
// copies it, refocuses that window and types the paste shortcut into it with
// wtype (Ctrl+Shift+V for terminals, Ctrl+V otherwise).
Singleton {
    id: root

    readonly property bool open: Panels.isOpen("clipboard")
    // Tab to open on (e.g. "emoji"), consumed by the panel when it opens.
    property string startTab: ""
    property string query: ""

    // [{ id, line, text, image, meta }] newest first
    property var entries: []
    readonly property var filtered: {
        const q = query.trim().toLowerCase();
        return q ? entries.filter(e => e.text.toLowerCase().includes(q)) : entries;
    }

    // Decoded thumbnails: { id: "file:///…" }
    property var thumbs: ({})
    readonly property string thumbDir: `${Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"}/qs-clipboard`

    // The window that had focus when the history opened: { toplevel, appClass }
    property var target: null
    property bool cliphistMissing: false
    property bool wtypeMissing: false

    function toggle(): void {
        Panels.toggle("clipboard");
    }

    function show(): void {
        Panels.open("clipboard");
    }

    function hide(): void {
        if (open)
            Panels.close();
    }

    // Fresh history and target window every time it opens.
    onOpenChanged: {
        if (!open)
            return;
        query = "";
        rememberTarget();
        reader.running = true;
    }

    // Copy the entry; with `paste`, also paste it into the remembered window.
    function pick(entry: var, paste: bool): void {
        if (!entry)
            return;
        hide();
        copier.paste = paste;
        copier.command = ["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "sh", entry.line];
        copier.running = true;
    }

    // Copy arbitrary text (a symbol, an emoji); with `paste`, also paste it
    // into the remembered window.
    function insert(text: string, paste: bool): void {
        if (!text)
            return;
        hide();
        copier.paste = paste;
        copier.command = ["sh", "-c", 'printf "%s" "$1" | wl-copy', "sh", text];
        copier.running = true;
    }

    // Remember the focused window as the paste target (other panels that
    // insert text, like compose, call this when they open).
    function rememberTarget(): void {
        target = Wm.activeWindow;
        wtypeCheck.running = true;
    }

    // Paste `text` into the remembered window without disturbing the
    // clipboard: the current clipboard is saved first and put back after the
    // paste, and `text` is removed from the history again.
    property string restoreText: ""
    readonly property string restoreDir: `${thumbDir}/restore`

    function insertRestoring(text: string): void {
        if (!text)
            return;
        restoreText = text;
        copier.paste = true;
        copier.command = ["sh", "-c", `
            d="$1"; mkdir -p "$d" && chmod 700 "$d"
            t=$(wl-paste --list-types 2>/dev/null | head -1)
            if [ -n "$t" ]; then
                wl-paste --no-newline --type "$t" > "$d/saved" 2>/dev/null
                printf "%s" "$t" > "$d/type"
            else
                rm -f "$d/saved" "$d/type"
            fi
            printf "%s" "$2" | wl-copy`, "sh", restoreDir, text];
        copier.running = true;
    }

    // Paste the nth newest entry (0 = latest) into the focused window,
    // without opening the panel.
    property int pendingPaste: -1

    function pasteIndex(n: int): void {
        pendingPaste = n;
        rememberTarget();
        reader.running = true;
    }

    function remove(entry: var): void {
        entries = entries.filter(e => e !== entry);
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist delete', "sh", entry.line]);
    }

    function wipe(): void {
        entries = [];
        thumbs = {};
        Quickshell.execDetached(["sh", "-c", 'cliphist wipe; rm -rf "$1"', "sh", thumbDir]);
    }

    function isTerminal(appClass: string): bool {
        const cls = appClass.toLowerCase();
        return Config.clipboard.terminals.some(t => cls === t.toLowerCase());
    }

    // Types the shortcut into whichever window has focus, which by now is
    // the target again.
    function sendPaste(): void {
        if (!target?.toplevel)
            return;
        const mods = isTerminal(target.appClass) ? ["-M", "ctrl", "-M", "shift"] : ["-M", "ctrl"];
        Quickshell.execDetached(["wtype", ...mods, "v", "-m", "shift", "-m", "ctrl"]);
    }

    // ── Reading history ──────────────────────────────────────────────────────

    Process {
        id: reader

        command: ["sh", "-c", "command -v cliphist >/dev/null || { echo MISSING; exit; }; cliphist list"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.startsWith("MISSING")) {
                    root.cliphistMissing = true;
                    return;
                }
                root.cliphistMissing = false;
                root.entries = text.split("\n").filter(l => l.includes("\t")).map(line => {
                    const tab = line.indexOf("\t");
                    const preview = line.slice(tab + 1);
                    const img = preview.match(/^\[\[ binary data (.+?) (\w+) (\d+x\d+) \]\]$/);
                    return {
                        id: line.slice(0, tab),
                        line,
                        text: img ? `image ${img[3]} ${img[2]}` : preview.replace(/\s+/g, " ").trim(),
                        image: !!img,
                        meta: img ? `${img[2].toUpperCase()} ${img[3].replace("x", "×")}` : ""
                    };
                });
                if (root.pendingPaste >= 0) {
                    const n = root.pendingPaste;
                    root.pendingPaste = -1;
                    root.pick(root.entries[n], true);
                    return;
                }
                thumbnailer.decode();
            }
        }
    }

    // Decode image entries (newest 40) to files once, for thumbnails.
    Process {
        id: thumbnailer

        function decode(): void {
            const ids = root.entries.filter(e => e.image).slice(0, 40).map(e => e.id);
            if (ids.length === 0 || running)
                return;
            command = ["sh", "-c", `
                dir="$1"; shift
                mkdir -p "$dir" && chmod 700 "$dir"
                for id in "$@"; do
                    f="$dir/$id"
                    [ -s "$f" ] || printf "%s\\t" "$id" | cliphist decode > "$f" 2>/dev/null
                    [ -s "$f" ] && echo "$id"
                done`, "sh", root.thumbDir, ...ids];
            running = true;
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const thumbs = {};
                for (const id of text.split("\n").filter(l => l))
                    thumbs[id] = `file://${root.thumbDir}/${id}`;
                root.thumbs = thumbs;
            }
        }
    }

    // ── Pasting ──────────────────────────────────────────────────────────────

    Process {
        id: copier

        property bool paste: false

        onExited: {
            if (!paste || !root.target?.toplevel)
                return;
            Wm.focusWindow(root.target);
            pasteDelay.restart();
        }
    }

    // Give focus and the new clipboard offer a moment to settle.
    Timer {
        id: pasteDelay
        interval: 120
        onTriggered: {
            root.sendPaste();
            if (root.restoreText)
                restoreDelay.restart();
        }
    }

    // After an insertRestoring() paste: previous clipboard back, text out of
    // the history (exact match only).
    Timer {
        id: restoreDelay
        interval: 500
        onTriggered: {
            Quickshell.execDetached(["sh", "-c", `
                d="$1"
                # Put the previous clipboard back; if it was empty, leave it empty.
                if [ -f "$d/saved" ]; then wl-copy --type "$(cat "$d/type")" < "$d/saved"; else wl-copy --clear; fi
                rm -f "$d/saved" "$d/type"
                sleep 0.3
                cliphist list | awk -F '\t' -v t="$2" '$2 == t { print; exit }' | cliphist delete`, "sh", root.restoreDir, root.restoreText]);
            root.restoreText = "";
        }
    }

    HealthCheck {
        source: "clipboard"
        ok: !root.cliphistMissing
        reason: "cliphist not found (install cliphist and run wl-paste --watch cliphist store)"
        grace: 0
    }

    // Checked at start and again before each paste, so installing wtype
    // while the shell runs clears the health tag.
    Process {
        id: wtypeCheck

        running: true
        command: ["sh", "-c", "command -v wtype"]
        onExited: code => root.wtypeMissing = code !== 0
    }

    HealthCheck {
        source: "paste"
        ok: !root.wtypeMissing
        reason: "wtype not found, so picked entries are copied but not pasted"
        grace: 0
    }

    // qs ipc call clipboard <toggle|open|close|paste N|symbols TAB>
    IpcHandler {
        target: "clipboard"

        function toggle(): void { root.toggle(); }
        function open(): void { root.show(); }
        function close(): void { root.hide(); }
        function paste(n: int): void { root.pasteIndex(n); }
        // Open on a symbol tab: emoji (default), nerd, symbol, kaomoji.
        function symbols(tab: string): void {
            root.startTab = tab || "emoji";
            root.show();
        }
    }
}
