pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

// Emoji, Nerd Font glyphs, symbols and kaomoji from assets/symbols.tsv
// (built from Unicode/CLDR/Nerd Fonts data by scripts/gen-symbols.sh). Loaded the first
// time something asks via load(); search(query, category) returns results.
Singleton {
    id: root

    // [{ cat, ch, name, hay }]
    property var all: []
    readonly property bool loaded: all.length > 0
    readonly property int maxResults: 600
    property string error: ""

    // refresh(): rerun scripts/gen-symbols.sh (downloads the Unicode, CLDR and
    // Nerd Fonts data, rebuilds kaomoji from assets/kaomoji.json). The file
    // watch below loads the result.
    readonly property bool refreshing: refresher.running
    property string refreshStatus: ""

    function refresh(): void {
        if (refresher.running)
            return;
        refreshStatus = "downloading…";
        refresher.running = true;
    }

    function load(): void {
        if (!file.path)
            file.path = Quickshell.shellPath("assets/symbols.tsv");
    }

    // Every word must match. Exact names rank first, then names containing the
    // whole query, then the rest. Results: { cat, ch, name, detail }.
    function search(query: string, category: string): var {
        const q = query.trim().toLowerCase();
        const words = q.split(/\s+/).filter(w => w);
        const exact = [], close = [], rest = [];
        for (const s of all) {
            if (s.cat !== category)
                continue;
            if (words.length && !words.every(w => s.hay.includes(w)))
                continue;
            const name = s.name.toLowerCase();
            (q && name === q ? exact : q && name.includes(q) ? close : rest).push(s);
            if (exact.length + close.length >= maxResults)
                break;
        }
        return [...exact, ...close, ...rest].slice(0, maxResults).map(s => ({
            cat: s.cat,
            ch: s.ch,
            name: s.name,
            detail: s.cat === "kaomoji" ? "kaomoji" : codepoints(s.ch)
        }));
    }

    function codepoints(ch: string): string {
        return [...ch].map(c => "U+" + c.codePointAt(0).toString(16).toUpperCase().padStart(4, "0")).join(" ");
    }

    FileView {
        id: file

        printErrors: false
        // Pick up a regenerated symbols.tsv without a shell reload.
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            root.error = "";
            retry.used = false;
            root.all = text().split("\n").filter(l => l).map(line => {
                const [cat, ch, name, keywords] = line.split("\t");
                return { cat, ch, name, hay: `${name} ${keywords ?? ""} ${cat}`.toLowerCase() };
            });
        }
        // A reload can land while the file is being swapped for a new one;
        // with data already loaded, give it a moment before calling it broken.
        onLoadFailed: error => {
            if (root.loaded && !retry.used) {
                retry.used = true;
                retry.start();
                return;
            }
            root.error = `cannot read assets/symbols.tsv: ${FileViewError.toString(error)}`;
        }
    }

    Timer {
        id: retry

        property bool used: false

        interval: 500
        onTriggered: file.reload()
    }

    Process {
        id: refresher

        command: [Quickshell.shellPath("scripts/gen-symbols.sh")]
        stdout: StdioCollector {
            id: refreshOut
        }
        stderr: StdioCollector {
            id: refreshErr
        }
        // The script's last line: "wrote N symbols…" or what went wrong.
        onExited: code => {
            const last = t => t.trim().split("\n").pop();
            root.refreshStatus = code === 0 ? last(refreshOut.text)
                : last(refreshErr.text) || `gen-symbols.sh failed (exit ${code})`;
        }
    }

    // qs ipc call symbols <refresh|search TAB QUERY>
    IpcHandler {
        target: "symbols"

        function refresh(): void { root.refresh(); }

        function search(tab: string, query: string): string {
            root.load();
            if (!root.loaded)
                return root.error || "loading, try again";
            return root.search(query, tab).map(s => `${s.ch}  ${s.name}`).join("\n");
        }
    }

    HealthCheck {
        source: "symbols"
        ok: root.error === ""
        reason: root.error
        grace: 0
    }
}
