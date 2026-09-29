pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The keyboard shortcuts cheat sheet (SUPER+F1): Sway's binds, read from the
// config Sway has loaded each time the panel opens, so it never goes stale.
//
// Sections come from the config's comments: the first comment line after a
// blank line titles the binds under it ("# Focus"), cut at a ":" or " (";
// "── N. Keys ──" banners and comments between binds are skipped. Sway allows
// no comment after a bind, so descriptions come from the tables below; a
// command they don't know shows as written. Super+1…6 style runs of binds
// collapse into one row.
Singleton {
    id: root

    readonly property bool open: Panels.isOpen("keys")

    // [{ title, binds: [{ mods: ["Super", "Shift"], key: "←", action }] }]
    property var groups: []
    property string error: ""
    readonly property int count: groups.reduce((n, g) => n + g.binds.length, 0)

    // Shell IPC calls ("$qs <target> <function>").
    readonly property var shellActions: ({
        "launcher toggle": "Launcher",
        "clipboard toggle": "Clipboard history",
        "clipboard symbols emoji": "Emoji and symbols",
        "notifications toggle": "Notifications",
        "control toggle": "Control center",
        "session toggle": "Session menu",
        "session lock": "Lock",
        "compose toggle": "Compose",
        "keys toggle": "This cheat sheet",
        "capture screenshot": "Screenshot",
        "capture record": "Record screen",
        "capture voice": "Record voice memo",
        "capture stop": "Stop recording",
        "audio up": "Volume up",
        "audio down": "Volume down",
        "audio mute": "Mute",
        "media toggle": "Play / pause",
        "media next": "Next track",
        "media previous": "Previous track"
    })

    // Sway commands, with variables expanded and a collapsed run's number as N.
    readonly property var swayActions: [
        [/^kill$/, "Close window"],
        [/^exec kill \$\(swaymsg/, "Quit app"],
        [/^fullscreen( toggle)?$/, "Fullscreen"],
        [/^floating toggle$/, "Float / tile"],
        [/^focus mode_toggle$/, "Focus floating ⇄ tiled"],
        [/^focus (up|down|left|right)$/, m => `Focus ${m[1]}`],
        [/^move (up|down|left|right)$/, m => `Move ${m[1]}`],
        [/^resize grow width/, "Wider"],
        [/^resize shrink width/, "Narrower"],
        [/^resize grow height/, "Taller"],
        [/^resize shrink height/, "Shorter"],
        [/^splith$/, "Next opens beside"],
        [/^splitv$/, "Next opens below"],
        [/^layout toggle split$/, "Side by side ⇄ stacked"],
        [/^layout toggle tabbed split$/, "Tabs on / off"],
        [/^focus parent$/, "Select parent"],
        [/^focus child$/, "Select child"],
        [/^workspace back_and_forth$/, "Previous workspace"],
        [/^workspace (?:number )?(\S+)$/, m => m[1] === "N" ? "Go to workspace" : `Workspace ${m[1]}`],
        [/^move container to workspace (?:number )?(\S+)(; workspace .*)?$/,
            m => m[1] === "N" ? "Take window to workspace" : `Take window to ${m[1]}`],
        [/^scratchpad show$/, "Show scratchpad"],
        [/^move scratchpad$/, "Send to scratchpad"],
        [/^reload$/, "Reload Sway config"],
        [/^exit$|^exec swaynag .*swaymsg exit/, "Exit Sway"]
    ]

    readonly property var modNames: ({
        Mod4: "Super", Mod1: "Alt", Mod5: "AltGr", Control: "Ctrl", Ctrl: "Ctrl", Shift: "Shift"
    })
    readonly property var keyNames: ({
        Return: "↵", Escape: "Esc", space: "Space", Tab: "Tab", period: ".", comma: ",",
        minus: "-", equal: "=", backslash: "\\", slash: "/", grave: "`", Print: "Print",
        Up: "↑", Down: "↓", Left: "←", Right: "→",
        XF86AudioRaiseVolume: "Vol+", XF86AudioLowerVolume: "Vol−", XF86AudioMute: "Mute",
        XF86AudioPlay: "Play", XF86AudioNext: "Next", XF86AudioPrev: "Prev"
    })
    readonly property var keycodes: ({ "66": "Caps" })

    function toggle(): void {
        Panels.toggle("keys");
    }

    function load(): void {
        if (!Wm.sway) {
            error = "only Sway's binds can be read";
            return;
        }
        reader.running = true;
    }

    onOpenChanged: {
        if (open)
            load();
    }
    Component.onCompleted: load()

    function expand(text: string, vars: var): string {
        return text.replace(/\$[A-Za-z_][A-Za-z0-9_]*/g, v => vars[v] ?? v);
    }

    function heading(comment: string): string {
        return comment.replace(/^#+\s*/, "").split(/:| \(/)[0].replace(/\.$/, "").trim();
    }

    function keyOf(combo: string, code: bool): var {
        const parts = combo.split("+");
        const last = parts.pop();
        const key = code ? keycodes[last] ?? `code ${last}`
            : keyNames[last] ?? (last.length === 1 ? last.toUpperCase() : last);
        return { mods: parts.map(p => modNames[p] ?? p), key: key };
    }

    function describe(command: string, vars: var): string {
        const ipc = command.match(/^exec\s+qs\b.*?\bipc\s+call\s+(.+)$/);
        if (ipc) {
            const call = ipc[1].trim();
            const [target, fn] = call.split(/\s+/);
            return shellActions[call] ?? (fn === "toggle" ? target.charAt(0).toUpperCase() + target.slice(1) : call);
        }
        for (const [pattern, label] of swayActions) {
            const m = command.match(pattern);
            if (m)
                return typeof label === "function" ? label(m) : label;
        }
        const exec = command.match(/^exec\s+(?:--no-startup-id\s+)?(.+)$/);
        if (exec) {
            const cmd = exec[1];
            if (vars.$term && cmd === vars.$term)
                return "Terminal";
            return vars.$term && cmd.startsWith(`${vars.$term} -e `) ? cmd.slice(vars.$term.length + 4) : cmd;
        }
        return command;
    }

    function parse(text: string): var {
        const vars = {};
        const groups = [];
        let title = "";
        let afterBlank = true;
        let mode = "";

        function add(bind: var, command: string): void {
            const name = mode ? `${mode} mode` : title || "Other";
            let group = groups.find(g => g.title === name);
            if (!group) {
                group = { title: name, binds: [] };
                groups.push(group);
            }

            // Runs of Mod+1, Mod+2, … doing the same thing to that number.
            const digit = /^[0-9]$/.test(bind.key);
            const shape = digit ? command.replace(new RegExp(`\\b${bind.key}\\b`, "g"), "N") : "";
            const prev = group.binds[group.binds.length - 1];
            if (digit && prev?.shape === shape && prev.mods.join("+") === bind.mods.join("+")
                    && Number(bind.key) === prev.last + 1) {
                prev.last = Number(bind.key);
                prev.key = `${prev.first}–${prev.last}`;
                prev.action = describe(shape, vars);
                return;
            }
            group.binds.push({
                mods: bind.mods,
                key: bind.key,
                action: describe(command, vars),
                shape: shape,
                first: Number(bind.key),
                last: Number(bind.key)
            });
        }

        for (const raw of text.split("\n")) {
            const line = raw.trim();
            if (line === "") {
                afterBlank = true;
                continue;
            }
            if (line.startsWith("#")) {
                if (afterBlank)
                    title = line.includes("──") ? "" : heading(line);
                afterBlank = false;
                continue;
            }
            afterBlank = false;

            let m = line.match(/^set\s+(\$\S+)\s+(.*)$/);
            if (m) {
                vars[m[1]] = expand(m[2], vars);
                continue;
            }
            m = line.match(/^mode\s+(?:--\S+\s+)*"?([^"{]+?)"?\s*\{$/);
            if (m) {
                mode = m[1];
                continue;
            }
            if (line === "}") {
                mode = "";
                continue;
            }
            m = line.match(/^(bindsym|bindcode)((?:\s+--\S+)*)\s+(\S+)\s+(.+)$/);
            if (m) {
                add(keyOf(expand(m[3], vars), m[1] === "bindcode"), expand(m[4], vars));
                continue;
            }
            // Super + drag moves / resizes floating windows.
            m = line.match(/^floating_modifier\s+(\S+)(?:\s+(normal|inverse))?/);
            if (m && m[1] !== "none") {
                const mods = keyOf(expand(m[1], vars) + "+x", false).mods;
                const inverse = m[2] === "inverse";
                let group = groups.find(g => g.title === "Mouse");
                if (!group) {
                    group = { title: "Mouse", binds: [] };
                    groups.push(group);
                }
                group.binds.push({ mods: mods, key: "Left drag", action: inverse ? "Resize floating" : "Move floating" });
                group.binds.push({ mods: mods, key: "Right drag", action: inverse ? "Move floating" : "Resize floating" });
            }
        }
        return groups;
    }

    function format(): string {
        return groups.map(g => [g.title.toUpperCase()]
            .concat(g.binds.map(b => `  ${b.mods.concat(b.key).join("+").padEnd(22)} ${b.action}`))
            .join("\n")).join("\n");
    }

    Process {
        id: reader

        command: ["swaymsg", "-r", "-t", "get_config"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.groups = root.parse(JSON.parse(text).config);
                    root.error = "";
                } catch (e) {
                    root.error = `couldn't read Sway's config: ${e}`;
                }
            }
        }
        onExited: code => {
            if (code !== 0)
                root.error = `swaymsg failed (exit ${code})`;
        }
    }

    // qs ipc call keys <toggle|open|close|list>
    IpcHandler {
        target: "keys"

        function toggle(): void { root.toggle(); }
        function open(): void { Panels.open("keys"); }
        function close(): void {
            if (root.open)
                Panels.close();
        }
        // What the panel shows, as text (rereads the config for next time).
        function list(): string {
            root.load();
            return root.error || root.format();
        }
    }
}
