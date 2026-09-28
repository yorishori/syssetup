pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

// Screenshots, screen recordings and voice memos, as one small state machine:
//
//   idle → selecting → marking → asking      (screenshot)
//   idle → selecting → recording → asking    (screen recording, wf-recorder)
//   idle → recording → asking                (voice memo, pw-record)
//
// The capture overlay (modules/capture) does the selecting and marking on a
// frozen frame; recordings stop with stop(). Results go to a private temp
// folder, and nothing is kept until the prompt's answer: save (to a path,
// remembering the folder per kind), copy (screenshots), both, or discard.
Singleton {
    id: root

    property string state: "idle"
    property string kind: ""     // "screenshot", "screen", "voice"
    property rect selection      // screen-local, for screenshots and recordings
    property var windows: []     // [{ x, y, w, h }] on the visible workspace, for snapping
    property string file: ""     // the temp result
    property real startedAt: 0
    property int elapsed: 0      // seconds, while recording
    property string error: ""

    readonly property bool busy: state !== "idle"
    readonly property bool recording: state === "recording"
    readonly property string tmpDir: `${Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"}/qs-capture`

    // Folder and file name the prompt suggests.
    readonly property string suggestedDir: kind === "screenshot" ? Config.capture.screenshots
        : kind === "screen" ? Config.capture.recordings : Config.capture.voice
    readonly property string extension: kind === "screenshot" ? "png" : kind === "screen" ? "mp4" : "ogg"

    function stamp(): string {
        return Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss");
    }

    function suggestedName(): string {
        const prefix = kind === "screenshot" ? "screenshot" : kind === "screen" ? "recording" : "voice";
        return `${suggestedDir}/${prefix}-${stamp()}.${extension}`;
    }

    // ── Starting ─────────────────────────────────────────────────────────────

    function screenshot(): void {
        begin("screenshot");
    }

    function recordScreen(): void {
        begin("screen");
    }

    function recordVoice(): void {
        if (busy)
            return;
        kind = "voice";
        file = `${tmpDir}/voice-${stamp()}.ogg`;
        startRecorder(["pw-record", file]);
    }

    function begin(what: string): void {
        if (busy)
            return;
        Panels.close();
        kind = what;
        error = "";
        selection = Qt.rect(0, 0, 0, 0);
        windowList.running = true;
        state = "selecting";
    }

    function cancel(): void {
        state = "idle";
        kind = "";
    }

    // The overlay reports the chosen area (screen-local coordinates).
    function selected(area: rect): void {
        selection = area;
        if (kind === "screenshot") {
            state = "marking";
        } else {
            // Start once the overlay is gone, so it isn't in the first frames.
            state = "starting";
            recordDelay.restart();
        }
    }

    // The overlay saved the marked screenshot here.
    function marked(path: string): void {
        file = path;
        state = "asking";
    }

    function stop(): void {
        if (recorder.running)
            recorder.signal(2);  // SIGINT: let it finish the file
    }

    function startRecorder(command: var): void {
        error = "";
        recorder.command = ["sh", "-c", 'mkdir -p "$1" && chmod 700 "$1"; shift; exec "$@"', "sh", tmpDir, ...command];
        recorder.running = true;
        startedAt = Date.now();
        elapsed = 0;
        state = "recording";
    }

    // ── Answering the prompt ─────────────────────────────────────────────────

    function save(path: string, alsoCopy: bool): void {
        const target = path.trim() || suggestedName();
        const dir = target.replace(/\/[^\/]*$/, "");
        const home = Quickshell.env("HOME");
        finisher.command = ["sh", "-c", `
            target="$1"; src="$2"
            mkdir -p "$(dirname "$target")" && mv -f "$src" "$target" || exit 1
            [ "$3" = copy ] && wl-copy --type image/png < "$target"
            exit 0`, "sh", target.replace(/^~(?=\/|$)/, home), file, alsoCopy ? "copy" : ""];
        finisher.running = true;
        // Remember the folder for next time.
        const key = kind === "screenshot" ? "screenshots" : kind === "screen" ? "recordings" : "voice";
        if (dir && dir !== Config.capture[key])
            Config.set(`capture.${key}`, dir);
        state = "idle";
    }

    function copy(): void {
        finisher.command = ["sh", "-c", 'wl-copy --type image/png < "$1"; rm -f "$1"', "sh", file];
        finisher.running = true;
        state = "idle";
    }

    function discard(): void {
        Quickshell.execDetached(["rm", "-f", file]);
        state = "idle";
    }

    // ── Processes ────────────────────────────────────────────────────────────

    Process {
        id: recorder

        stderr: StdioCollector {
            id: recorderErr
        }
        onExited: code => {
            if (root.state !== "recording")
                return;
            // 127: not installed. Anything else after a normal SIGINT is fine
            // as long as the file exists; the prompt shows what we have.
            if (code === 127) {
                root.error = `${root.kind === "voice" ? "pw-record" : "wf-recorder"} not found`;
                root.state = "idle";
                return;
            }
            root.state = "asking";
        }
    }

    Timer {
        id: recordDelay
        interval: 250
        onTriggered: {
            const s = Display.primary;
            const a = root.selection;
            const g = `${Math.round(s.x + a.x)},${Math.round(s.y + a.y)} ${Math.round(a.width)}x${Math.round(a.height)}`;
            root.file = `${root.tmpDir}/recording-${root.stamp()}.mp4`;
            root.startRecorder(["wf-recorder", "-g", g, "-f", root.file]);
        }
    }

    Component.onCompleted: Quickshell.execDetached(["sh", "-c", 'mkdir -p "$1" && chmod 700 "$1"', "sh", tmpDir])

    Timer {
        interval: 1000
        repeat: true
        running: root.recording
        onTriggered: root.elapsed = Math.round((Date.now() - root.startedAt) / 1000)
    }

    // Windows on the primary screen's visible workspace, for snapping.
    Process {
        id: windowList

        command: Wm.sway ? ["swaymsg", "-r", "-t", "get_tree"]
            : ["sh", "-c", "hyprctl monitors -j; echo '---'; hyprctl clients -j"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (Wm.sway) {
                    root.windows = root.swayWindows(text);
                    return;
                }
                try {
                    const [monitorsJson, clientsJson] = text.split("\n---\n");
                    const mon = JSON.parse(monitorsJson).find(m => m.name === Display.primary?.name);
                    const visible = [mon?.activeWorkspace?.id, mon?.specialWorkspace?.id].filter(id => id);
                    root.windows = JSON.parse(clientsJson)
                        .filter(c => c.mapped && !c.hidden && visible.includes(c.workspace.id))
                        .map(c => ({ x: c.at[0] - mon.x, y: c.at[1] - mon.y, w: c.size[0], h: c.size[1] }))
                        .reverse();  // topmost first (roughly: floating windows come last in the list)
                } catch (e) {
                    root.windows = [];
                }
            }
        }
    }

    // Visible windows in Sway's tree, on the primary output, floating ones
    // (topmost, and any scratchpad window on show) first. `rect` includes the
    // border, which is fine for snapping.
    function swayWindows(json: string): var {
        try {
            const out = JSON.parse(json).nodes.find(o => o.name === Display.primary?.name);
            if (!out)
                return [];
            const floating = [];
            const tiled = [];
            const walk = (node, isFloating) => {
                const children = [...(node.floating_nodes ?? []), ...(node.nodes ?? [])];
                if (children.length === 0) {
                    if (node.visible && (node.type === "con" || node.type === "floating_con"))
                        (isFloating ? floating : tiled).push(node.rect);
                    return;
                }
                for (const n of node.floating_nodes ?? [])
                    walk(n, true);
                for (const n of node.nodes ?? [])
                    walk(n, isFloating);
            };
            walk(out, false);
            return [...floating, ...tiled].map(r => ({ x: r.x - out.rect.x, y: r.y - out.rect.y, w: r.width, h: r.height }));
        } catch (e) {
            return [];
        }
    }

    Process {
        id: finisher

        onExited: code => {
            if (code !== 0)
                Quickshell.execDetached(["notify-send", "-a", "qs", "Capture not saved", "Could not write the file; it's still in " + root.tmpDir]);
        }
    }

    HealthCheck {
        source: "capture"
        ok: root.error === ""
        reason: root.error
        grace: 0
    }

    // qs ipc call capture <screenshot|record|voice|stop|discard|status>
    IpcHandler {
        target: "capture"

        function screenshot(): void { root.screenshot(); }
        function record(): void { root.recordScreen(); }
        function voice(): void { root.recordVoice(); }
        function stop(): void { root.stop(); }
        function discard(): void {
            if (root.state === "asking")
                root.discard();
            else if (root.state === "selecting" || root.state === "marking")
                root.cancel();
        }
        function status(): string {
            return root.recording ? `recording ${root.kind} for ${root.elapsed}s` : root.state;
        }
    }
}
