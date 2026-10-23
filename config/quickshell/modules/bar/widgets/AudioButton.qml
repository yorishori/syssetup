import QtQuick
import qs.components
import qs.services

// The output: its volume, muted, a player playing (MPRIS; the Pipewire peak
// meter doesn't support pro-audio devices). Click opens the audio drop,
// middle click mutes, scroll changes the volume.
Skinned {
    id: root

    readonly property bool ready: Audio.ready
    readonly property real volume: Audio.volume
    readonly property bool muted: Audio.muted
    readonly property bool off: !ready || muted
    readonly property bool playing: Media.playing
    readonly property bool hovered: area.containsMouse

    signal toggleDrop

    skin: "AudioButton"

    MouseArea {
        id: area

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton)
                Audio.toggleMute();
            else
                root.toggleDrop();
        }
        onWheel: wheel => Audio.changeVolume(wheel.angleDelta.y > 0 ? 0.05 : -0.05)
    }
}
