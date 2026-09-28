pragma Singleton

import QtQuick
import Quickshell
import qs.core
import Quickshell.Io
import Quickshell.Services.Mpris

// The current media player (MPRIS): the one the user picked, else whichever is
// playing, else the last one that played, else any. Having no player is normal, not an error.
Singleton {
    id: root

    // playerctld only mirrors other players; skip it to avoid duplicates.
    readonly property var players: Mpris.players.values.filter(p => !p.dbusName.endsWith(".playerctld"))
    readonly property MprisPlayer playingPlayer: players.find(p => p.isPlaying) ?? null
    property MprisPlayer lastPlayed: null  // becomes null if that player exits
    onPlayingPlayerChanged: if (playingPlayer) lastPlayed = playingPlayer

    // Picked by the user; when null (or gone), follow the automatic choice.
    property MprisPlayer chosen: null
    readonly property MprisPlayer player: (players.includes(chosen) ? chosen : null) ?? playingPlayer ?? lastPlayed ?? players[0] ?? null
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string title: player?.trackTitle ?? ""
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string icon: iconFor(player)
    // Cover art of the current track ("" if the player doesn't provide one).
    readonly property string art: player?.trackArtUrl ?? ""

    function iconFor(p: MprisPlayer): string {
        DesktopEntries.applications.values; // re-evaluate once entries have loaded
        const entry = p ? DesktopEntries.heuristicLookup(p.desktopEntry || p.identity) : null;
        return Icons.url(entry?.icon ?? "");
    }

    function select(p: MprisPlayer): void {
        chosen = p;
    }

    function togglePlaying(): void {
        if (player?.canTogglePlaying)
            player.togglePlaying();
    }

    function next(): void {
        if (player?.canGoNext)
            player.next();
    }

    function previous(): void {
        if (player?.canGoPrevious)
            player.previous();
    }

    // qs ipc call media <toggle|next|previous|get>
    IpcHandler {
        target: "media"

        function toggle(): void { root.togglePlaying(); }
        function next(): void { root.next(); }
        function previous(): void { root.previous(); }
        function get(): string {
            if (!root.player)
                return "no player";
            return `${root.playing ? "playing" : "paused"}: ${root.artist} - ${root.title} (${root.player.identity})`;
        }
    }
}
