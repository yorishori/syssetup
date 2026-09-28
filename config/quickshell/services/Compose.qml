pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

// Compose, done by the shell: sequences from the system Compose table (and
// ~/.XCompose if present), searched as you type, and the result pasted into
// the window you were in (clipboard restored afterwards).
//
// Only sequences made of typeable keys are kept (<Multi_key> ' e → é). If
// what you type starts no sequence, results match by name instead ("euro").
Singleton {
    id: root

    readonly property bool open: Panels.isOpen("compose")

    // [{ seq, result, name }]
    property var entries: []
    readonly property bool loaded: entries.length > 0

    // Keysym names → the character typed for them.
    readonly property var keysyms: ({
        space: " ", exclam: "!", quotedbl: "\"", numbersign: "#", dollar: "$", percent: "%",
        ampersand: "&", apostrophe: "'", parenleft: "(", parenright: ")", asterisk: "*",
        plus: "+", comma: ",", minus: "-", period: ".", slash: "/", colon: ":", semicolon: ";",
        less: "<", equal: "=", greater: ">", question: "?", at: "@", bracketleft: "[",
        backslash: "\\", bracketright: "]", asciicircum: "^", underscore: "_", grave: "`",
        braceleft: "{", bar: "|", braceright: "}", asciitilde: "~"
    })

    function toggle(): void {
        Panels.toggle("compose");
    }

    function keyChar(name: string): string {
        if (/^[A-Za-z0-9]$/.test(name))
            return name;
        return keysyms[name] ?? "";
    }

    function parse(text: string): var {
        const out = [];
        const line = /^<Multi_key>((?:\s*<[^>]+>)+)\s*:\s*"((?:[^"\\]|\\.)*)"[^#]*(?:#\s*(.*))?$/;
        for (const raw of text.split("\n")) {
            const m = raw.match(line);
            if (!m)
                continue;
            const keys = (m[1].match(/<[^>]+>/g) ?? []).map(k => keyChar(k.slice(1, -1)));
            if (keys.some(k => k === ""))
                continue;
            out.push({
                seq: keys.join(""),
                result: m[2].replace(/\\(.)/g, "$1"),
                name: (m[3] ?? "").trim().toLowerCase()
            });
        }
        return out;
    }

    // Matches for what was typed: sequences starting with it (shortest first),
    // or, if none, names containing it.
    function search(typed: string): var {
        if (!typed)
            return [];
        const bySeq = entries.filter(e => e.seq.startsWith(typed))
            .sort((a, b) => a.seq.length - b.seq.length || a.seq.localeCompare(b.seq));
        if (bySeq.length > 0)
            return bySeq.slice(0, 96);
        const q = typed.toLowerCase();
        return entries.filter(e => e.name.includes(q)).slice(0, 96);
    }

    // The one result to insert right away: typed is a complete sequence that
    // no longer sequence continues.
    function complete(typed: string): var {
        const exact = entries.filter(e => e.seq === typed);
        if (exact.length !== 1)
            return null;
        return entries.some(e => e.seq !== typed && e.seq.startsWith(typed)) ? null : exact[0];
    }

    function insert(result: string): void {
        Panels.close();
        Clipboard.insertRestoring(result);
    }

    onOpenChanged: {
        if (open)
            Clipboard.rememberTarget();
    }

    // System table, then the user's (user sequences win on duplicates).
    FileView {
        id: systemTable

        path: "/usr/share/X11/locale/en_US.UTF-8/Compose"
        printErrors: false
        onLoaded: root.merge()
    }
    FileView {
        id: userTable

        path: `${Quickshell.env("HOME")}/.XCompose`
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.merge()
    }

    function merge(): void {
        const bySeq = {};
        for (const e of parse(systemTable.loaded ? systemTable.text() : ""))
            bySeq[e.seq] = e;
        for (const e of parse(userTable.loaded ? userTable.text() : ""))
            bySeq[e.seq] = e;
        entries = Object.values(bySeq);
    }

    // qs ipc call compose <toggle|open|close|lookup TEXT>
    IpcHandler {
        target: "compose"

        function toggle(): void { root.toggle(); }
        function open(): void { Panels.open("compose"); }
        function close(): void {
            if (root.open)
                Panels.close();
        }
        function lookup(typed: string): string {
            return root.search(typed).slice(0, 10).map(e => `${e.seq}  →  ${e.result}  ${e.name}`).join("\n") || "no match";
        }
    }
}
