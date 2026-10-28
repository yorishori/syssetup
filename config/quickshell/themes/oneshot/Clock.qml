import QtQuick
import qs.components as C
import qs.core
import qs.modules.bar.widgets as W

// A little moon, the time, the date in small capitals. Amber while the
// calendar is open.
Row {
    id: root

    required property W.Clock control

    spacing: 8

    Glyph {
        anchors.verticalCenter: parent.verticalCenter
        text: "\u{F0904}"
        color: root.control.active ? Theme.palette.accent : Theme.palette.dim
    }
    C.StyledText {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(root.control.now, "HH:mm")
        color: root.control.active ? Theme.palette.accent : Theme.palette.fg
        font.pixelSize: Theme.font.size + 3
        font.weight: Font.DemiBold
    }
    C.StyledText {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(root.control.now, "ddd d MMM")
        caps: true
        color: root.control.hovered || root.control.active ? Theme.palette.fg : Theme.palette.dim
        font.family: Theme.get("font.labels") ?? Theme.font.family
        font.pixelSize: Theme.font.size - 3
    }
}
