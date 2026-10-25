import QtQuick
import qs.components as C
import qs.core
import qs.modules.audio as M

// The mute key and its LED.
Row {
    id: mute

    required property M.AudioPanel panel
    property var nodes: []
    readonly property bool muted: nodes[0]?.audio?.muted ?? false

    spacing: 8

    Led {
        anchors.verticalCenter: parent.verticalCenter
        size: 8
        on: mute.muted
        color: Theme.palette.error
    }
    C.IconButton {
        size: 28
        icon: mute.muted ? "\u{F075F}" : "\u{F057E}"
        iconColor: mute.muted ? Theme.palette.error : Theme.palette.fg
        onClicked: mute.panel.setMuted(mute.nodes, !mute.muted)
    }
}
