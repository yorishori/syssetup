import QtQuick
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import qs.components
import qs.services

// Audio: now playing (the current player, the others to switch to), then
// output, input and the apps' streams, each with its level and devices. The
// skin (AudioMenu) lays it out; everything it does goes through here.
Skinned {
    id: root

    property bool open: false

    // Now playing.
    readonly property var players: Media.players
    readonly property MprisPlayer player: Media.player
    readonly property bool playing: Media.playing
    readonly property string title: Media.title
    readonly property string artist: Media.artist
    readonly property string art: Media.art
    readonly property string icon: Media.icon
    // How far through the track (0-1), or -1 when the player doesn't say.
    // Kept current while the panel is open.
    readonly property real progress: player?.positionSupported && player?.lengthSupported && player.length > 0
        ? Math.max(0, Math.min(1, player.position / player.length)) : -1

    // Levels and devices.
    readonly property PwNode output: Audio.output
    readonly property PwNode input: Audio.input
    readonly property var outputs: Audio.outputs
    readonly property var inputs: Audio.inputs
    readonly property var apps: Audio.apps  // [{ name, nodes }]
    readonly property var outputProfiles: Audio.outputProfiles
    readonly property var inputProfiles: Audio.inputProfiles

    function iconFor(p: MprisPlayer): string {
        return Media.iconFor(p);
    }
    function select(p: MprisPlayer): void {
        Media.select(p);
    }
    function togglePlaying(): void {
        Media.togglePlaying();
    }
    function next(): void {
        Media.next();
    }
    function previous(): void {
        Media.previous();
    }

    function nodeName(node: PwNode): string {
        return Audio.nodeName(node);
    }
    function nodeIcon(node: PwNode): string {
        return Audio.nodeIcon(node);
    }
    function setDefaultOutput(node: PwNode): void {
        Audio.setDefaultOutput(node);
    }
    function setDefaultInput(node: PwNode): void {
        Audio.setDefaultInput(node);
    }
    // Level and mute for some nodes together (an app's streams).
    function setLevel(nodes: var, value: real): void {
        for (const n of nodes)
            Audio.setNodeVolume(n, value);
    }
    function setMuted(nodes: var, muted: bool): void {
        for (const n of nodes)
            if (n?.audio)
                n.audio.muted = muted;
    }

    skin: "AudioMenu"

    // MPRIS doesn't push the position as it plays; ask while it shows.
    Timer {
        interval: 1000
        running: root.open && root.playing
        repeat: true
        triggeredOnStart: true
        onTriggered: root.player?.positionChanged()
    }
}
