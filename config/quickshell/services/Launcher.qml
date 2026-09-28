pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

// Launcher logic (no UI): "go somewhere or run something". Two modes:
//   search  - the default, described below
//   apps    - every app, alphabetical, filtered by the query
// In search mode it turns `query` into `results`:
//   calc    - the query looks like math: qalc's answer (Enter copies it)
//   window  - an app that's already open: Enter focuses it
//   app     - a desktop entry: Enter launches it
//   custom  - an entry from config.json → launcher.entries
//   web     - always last: search the web for the query
// Every result has run(newInstance); newInstance (Shift+Enter) launches an
// app even if it's already open.
Singleton {
    id: root

    property string query: ""
    property string mode: "search"

    // From config.json → launcher.
    readonly property var terminal: Config.launcher.terminal
    readonly property string searchUrl: Config.launcher.search
    readonly property var customEntries: Config.launcher.entries.filter(e => e.name && e.command)

    property string calcResult: ""
    property bool qalcMissing: false

    // Desktop entry id of the default browser, to focus it after a web search.
    property string browserId: ""

    readonly property int maxResults: 8
    readonly property var apps: DesktopEntries.applications.values
        .filter(a => !a.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))
    readonly property var results: mode === "apps" ? buildApps(query.trim().toLowerCase(), apps, Wm.windows)
        : build(query.trim(), calcResult, apps, customEntries, Wm.windows)

    // ── Matching ─────────────────────────────────────────────────────────────

    // How well `text` matches `q` (lowercase): exact > prefix > word prefix >
    // substring > in-order letters (only if `loose`); 0 = no match.
    function score(text: string, q: string, loose: bool): int {
        if (!text)
            return 0;
        text = text.toLowerCase();
        if (text === q)
            return 100;
        if (text.startsWith(q))
            return 80;
        if (text.split(/[\s\-_.]+/).some(w => w.startsWith(q)))
            return 60;
        if (text.includes(q))
            return 40;
        if (!loose || q.length < 2)
            return 0;
        let i = 0;
        for (const ch of text)
            if (ch === q[i] && ++i === q.length)
                return 20;
        return 0;
    }

    // Names may match loosely (letters in order); descriptions and keywords
    // must contain the query, or they flood the list with noise.
    function bestScore(name: string, others: var, q: string): int {
        return Math.max(score(name, q, true), ...others.map(o => Math.floor(score(o, q, false) * 0.7)));
    }

    function windowFor(app: DesktopEntry): var {
        const cls = (app.startupClass || app.id).toLowerCase();
        return Wm.windows.find(w => w.appClass.toLowerCase() === cls) ?? null;
    }

    function looksLikeMath(q: string): bool {
        return /\d/.test(q) && /[-+*\/^%()=]|\bto\b|\bin\b|sqrt|sin|cos|tan|log|ln|!/.test(q);
    }

    // ── Results ──────────────────────────────────────────────────────────────

    function build(q: string, calc: string, apps: var, custom: var, windows: var): var {
        const lq = q.toLowerCase();
        const out = [];

        if (calc)
            out.push({
                kind: "calc", name: calc, detail: q, icon: "", glyph: "=",
                run: () => Quickshell.execDetached(["wl-copy", calc])
            });

        const candidates = [];
        for (const entry of custom) {
            const s = q ? bestScore(entry.name, [entry.description ?? "", ...(entry.keywords ?? [])], lq) : 1;
            if (s > 0)
                candidates.push({ s: s + 10, r: customResult(entry) });
        }
        if (q) {
            for (const app of apps) {
                const s = bestScore(app.name, [app.genericName, app.id, ...app.keywords], lq);
                if (s > 0)
                    candidates.push({ s, r: appResult(app) });
            }
        }
        candidates.sort((a, b) => b.s - a.s);
        // With good matches around, drop the letters-in-order guesses.
        const best = candidates[0]?.s ?? 0;
        out.push(...candidates.filter(c => best < 40 || c.s >= 30).slice(0, maxResults).map(c => c.r));

        if (q)
            out.push({
                kind: "web", name: q, detail: "search the web", icon: "", glyph: "\u{F059F}",
                run: () => searchWeb(q)
            });

        return out;
    }

    // Open the search in the default browser, then focus the browser if it's
    // already open (on Wayland it can't raise itself).
    function searchWeb(q: string): void {
        Quickshell.execDetached(["xdg-open", searchUrl.replace("%s", encodeURIComponent(q))]);
        const browser = browserId ? DesktopEntries.byId(browserId) : null;
        const win = browser ? windowFor(browser) : null;
        if (win)
            Wm.focusWindow(win);
    }

    function buildApps(q: string, apps: var, windows: var): var {
        return apps
            .filter(a => !q || [a.name, a.genericName, a.id, ...a.keywords].some(t => t && t.toLowerCase().includes(q)))
            .map(a => appResult(a));
    }

    function appResult(app: DesktopEntry): var {
        const win = windowFor(app);
        const launch = () => app.runInTerminal
            ? Quickshell.execDetached([...terminal, ...app.command])
            : app.execute();
        return {
            kind: win ? "window" : "app",
            name: app.name,
            detail: win ? win.title : (app.genericName || app.comment || ""),
            icon: Icons.url(app.icon),
            glyph: "",
            run: newInstance => win && !newInstance ? Wm.focusWindow(win) : launch()
        };
    }

    // Run a shell command in the configured terminal (config.json → launcher.terminal).
    function runInTerminal(command: string): void {
        Quickshell.execDetached([...terminal, "sh", "-c", command]);
    }

    function customResult(entry: var): var {
        const cmd = ["sh", "-c", entry.command];
        return {
            kind: "custom",
            name: entry.name,
            detail: entry.description ?? entry.command,
            icon: Icons.url(entry.icon ?? ""),
            glyph: entry.icon ? "" : "\u{F018D}",
            run: () => Quickshell.execDetached(entry.terminal ? [...terminal, ...cmd] : cmd)
        };
    }

    // ── Calculator (qalc) ────────────────────────────────────────────────────

    onQueryChanged: {
        if (looksLikeMath(query.trim()))
            calcDebounce.restart();
        else
            calcResult = "";
    }

    Timer {
        id: calcDebounce
        interval: 120
        onTriggered: {
            calc.command = ["qalc", "-t", root.query.trim()];
            calc.running = true;
        }
    }

    Process {
        id: calc

        stdout: StdioCollector {
            onStreamFinished: {
                const answer = text.trim();
                // qalc echoes things it can't compute; only keep real answers.
                root.calcResult = answer && answer !== root.query.trim() && !answer.includes("error") ? answer : "";
            }
        }
        onExited: code => {
            if (code === 127)
                root.qalcMissing = true;
        }
    }

    HealthCheck {
        source: "launcher"
        ok: !root.qalcMissing
        reason: "qalc not found; calculator disabled"
        grace: 0
    }

    Process {
        running: true
        command: ["xdg-settings", "get", "default-web-browser"]
        stdout: StdioCollector {
            onStreamFinished: root.browserId = text.trim().replace(/\.desktop$/, "")
        }
    }

    // qs ipc call launcher <toggle|open|close|search QUERY|apps|list QUERY>
    IpcHandler {
        target: "launcher"

        function toggle(): void { Panels.toggle("launcher"); }
        function open(): void { Panels.open("launcher"); }
        function close(): void {
            if (Panels.isOpen("launcher"))
                Panels.close();
        }
        // Open pre-filled with a query.
        function search(q: string): void {
            Panels.open("launcher");
            root.query = q;
        }
        function apps(): void {
            Panels.open("launcher");
            root.mode = "apps";
        }
        function list(q: string): string {
            root.query = q;
            return root.results.map(r => `${r.kind.padEnd(6)} ${r.name}${r.detail ? "  (" + r.detail + ")" : ""}`).join("\n");
        }
    }
}
