import QtQuick
import qs.core
import qs.services

// Audio at a glance: dim red + crossed out when off, glowing accent while a
// media player is playing (MPRIS; the Pipewire peak meter doesn't support pro-audio
// devices), dim otherwise. Click opens the audio drop, middle click mutes, scroll
// changes volume.
BarLabel {
    id: root

    signal toggleDrop

    readonly property bool off: !Audio.ready || Audio.muted

    text: off ? "\u{F075F}" : "\u{F057E}"
    lit: !off && Media.playing
    color: off ? Config.colors.off : lit ? Config.colors.accent : Config.colors.dim

    Behavior on color {
        ColorAnimation { duration: 250 }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
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
