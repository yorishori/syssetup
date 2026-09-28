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

    function nodeName(node: PwNode): string {
        return node?.properties["application.name"] || node?.description || node?.nickname || node?.name || "";
    }

    function nodeIcon(node: PwNode): string {
        DesktopEntries.applications.values; // re-evaluate once entries have loaded
        const name = node?.properties["application.icon-name"] || nodeName(node);
        const entry = name ? DesktopEntries.heuristicLookup(name) : null;
        return Icons.url(entry?.icon || name.toLowerCase());
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

    // qs ipc call audio <toggle|open|close|up|down|mute|set N|get>
    IpcHandler {
        target: "audio"

        function toggle(): void { Panels.toggle("audio"); }
        function open(): void { Panels.open("audio"); }
        function close(): void {
            if (Panels.isOpen("audio"))
                Panels.close();
        }

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
