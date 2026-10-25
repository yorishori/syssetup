pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.core

// Audio devices, app streams and volumes, via Pipewire.
Singleton {
    id: root

    readonly property var nodes: Pipewire.nodes.values
    readonly property var outputs: nodes.filter(n => n.type === PwNodeType.AudioSink)
    readonly property var inputs: nodes.filter(n => n.type === PwNodeType.AudioSource)
    readonly property var streams: nodes.filter(n => n.type === PwNodeType.AudioOutStream)
    // Streams grouped per app ({ name, nodes }); apps often open several
    // indistinguishable streams, so the mixer controls them together.
    readonly property var apps: {
        const groups = {};
        for (const stream of streams) {
            const name = nodeName(stream);
            groups[name] = [...(groups[name] ?? []), stream];
        }
        return Object.entries(groups).map(([name, nodes]) => ({ name, nodes }));
    }

    readonly property PwNode output: Pipewire.defaultAudioSink
    readonly property PwNode input: Pipewire.defaultAudioSource

    // One node per device, in a steady order: a device's profile can give it
    // several sinks or sources (Pro Audio, HDMI), which are one choice here.
    // A device stands for the default when that's one of its nodes, else for
    // its preferred node. Nodes without a device stand for themselves.
    readonly property var outputDevices: perDevice(outputs, output)
    readonly property var inputDevices: perDevice(inputs, input)

    function deviceOf(node: PwNode): string {
        return node?.properties["device.id"] ?? "";
    }

    function priority(node: PwNode): int {
        return Number(node?.properties["priority.session"]) || 0;
    }

    function perDevice(list: var, current: PwNode): var {
        const groups = [];
        const byKey = {};
        for (const node of list) {
            const key = deviceOf(node) || `node ${node.id}`;
            if (!(key in byKey)) {
                byKey[key] = groups.length;
                groups.push([]);
            }
            groups[byKey[key]].push(node);
        }
        return groups.map(nodes => nodes.includes(current) ? current
            : nodes.reduce((best, n) => priority(n) > priority(best) ? n : best));
    }

    // The best node of a device in a list.
    function nodeOn(list: var, device: string): PwNode {
        return list.filter(n => deviceOf(n) === device)
            .reduce((best, n) => !best || priority(n) > priority(best) ? n : best, null);
    }

    // A profile switch recreates the device's node, and meanwhile WirePlumber
    // may make another device the default. For a few seconds after one, the
    // default is put back on the switched device as soon as its new node is
    // there.
    property string holdOutput: ""
    property string holdInput: ""

    function hold(kind: string, device: string): void {
        if (kind === "output")
            holdOutput = device;
        else
            holdInput = device;
        holdTimer.restart();
        keep();
    }

    function keep(): void {
        if (holdOutput !== "" && deviceOf(output) !== holdOutput) {
            const node = nodeOn(outputs, holdOutput);
            if (node)
                Pipewire.preferredDefaultAudioSink = node;
        }
        if (holdInput !== "" && deviceOf(input) !== holdInput) {
            const node = nodeOn(inputs, holdInput);
            if (node)
                Pipewire.preferredDefaultAudioSource = node;
        }
    }

    onOutputsChanged: keep()
    onOutputChanged: keep()
    onInputsChanged: keep()
    onInputChanged: keep()

    Timer {
        id: holdTimer

        interval: 4000
        onTriggered: {
            root.holdOutput = "";
            root.holdInput = "";
        }
    }
    readonly property bool ready: Pipewire.ready && !!output?.audio

    // Master (default output) shortcuts.
    readonly property real volume: output?.audio?.volume ?? 0
    readonly property bool muted: output?.audio?.muted ?? false
    readonly property int percent: Math.round(volume * 100)

    function setNodeVolume(node: PwNode, value: real): void {
        if (node?.audio)
            node.audio.volume = Math.max(0, Math.min(1, value));
    }

    function toggleNodeMute(node: PwNode): void {
        if (node?.audio)
            node.audio.muted = !node.audio.muted;
    }

    function setVolume(value: real): void { setNodeVolume(output, value); }
    function changeVolume(delta: real): void { setNodeVolume(output, volume + delta); }
    function toggleMute(): void { toggleNodeMute(output); }

    function setDefaultOutput(node: PwNode): void { Pipewire.preferredDefaultAudioSink = node; }
    function setDefaultInput(node: PwNode): void { Pipewire.preferredDefaultAudioSource = node; }

    // Profiles of the devices behind the default output and input:
    // { list: [{ index, label, current }] (best first), current, switching, set(index) }.
    readonly property DeviceProfiles outputProfiles: DeviceProfiles {
        node: root.output
        kind: "output"
    }
    readonly property DeviceProfiles inputProfiles: DeviceProfiles {
        node: root.input
        kind: "input"
    }

    // "High Fidelity Playback (A2DP Sink, codec LDAC)" -> "A2DP LDAC"; others as is.
    function profileLabel(description: string): string {
        const m = description.match(/\(([^,)]+?)(?: (?:Sink|Source))?, codec ([^)]+)\)/);
        return m ? `${m[1]} ${m[2]}` : description;
    }

    function nodeName(node: PwNode): string {
        return node?.properties["application.name"] || node?.description || node?.nickname || node?.name || "";
    }

    function nodeIcon(node: PwNode): string {
        DesktopEntries.applications.values; // re-evaluate once entries have loaded
        const name = node?.properties["application.icon-name"] || nodeName(node);
        const entry = name ? DesktopEntries.heuristicLookup(name) : null;
        return Icons.url(entry?.icon || name.toLowerCase());
    }

    // Quickshell doesn't expose PipeWire devices, so profiles are read with
    // pw-dump and set with wpctl, which also has WirePlumber remember the
    // choice for that device.
    component DeviceProfiles: Scope {
        id: profiles

        required property PwNode node
        required property string kind  // "output" or "input"
        readonly property string device: node?.properties["device.id"] ?? ""
        property var list: []
        readonly property var current: list.find(p => p.current) ?? null
        readonly property bool switching: writer.running

        // A profile switch recreates the node, so this also catches switches
        // made elsewhere. Debounced: the node's properties can land after it.
        onNodeChanged: debounce.restart()
        onDeviceChanged: debounce.restart()

        function load(): void {
            if (device === "") {
                list = [];
                return;
            }
            reader.command = ["pw-dump", device];
            reader.running = true;
        }

        function set(index: int): void {
            if (device === "" || writer.running)
                return;
            root.hold(kind, device);
            writer.command = ["wpctl", "set-profile", device, String(index)];
            writer.running = true;
        }

        Process {
            id: reader

            stdout: StdioCollector {
                onStreamFinished: {
                    let params = {};
                    try {
                        params = JSON.parse(text)[0]?.info?.params ?? {};
                    } catch (e) {
                        return;
                    }
                    const current = params.Profile?.[0]?.index;
                    // "off" would take the device out of the lists, with no way back here.
                    profiles.list = (params.EnumProfile ?? [])
                        .filter(p => p.name !== "off" && p.available !== "no")
                        .sort((a, b) => (b.priority ?? 0) - (a.priority ?? 0))
                        .map(p => ({ index: p.index, label: root.profileLabel(p.description ?? p.name), current: p.index === current }));
                }
            }
        }

        // In case the node isn't replaced (or the switch failed).
        Process {
            id: writer

            onExited: debounce.restart()
        }

        Timer {
            id: debounce
            interval: 300
            onTriggered: profiles.load()
        }
    }

    // Pipewire only keeps node properties up to date while they are tracked.
    PwObjectTracker {
        objects: [...root.outputs, ...root.inputs, ...root.streams]
    }

    HealthCheck {
        source: "audio"
        ok: root.ready
        reason: Pipewire.ready ? "no default output device" : "cannot connect to Pipewire"
    }

    // qs ipc call audio <up|down|mute|set N|get>
    IpcHandler {
        target: "audio"

        function up(): void { root.changeVolume(0.05); }
        function down(): void { root.changeVolume(-0.05); }
        function mute(): void { root.toggleMute(); }
        function set(percent: int): void { root.setVolume(percent / 100); }
        function get(): string {
            if (!root.ready)
                return "unavailable";
            return `${root.percent}%${root.muted ? " (muted)" : ""} on ${root.nodeName(root.output)}`;
        }
    }
}
