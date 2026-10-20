import QtQuick
import qs.core
import qs.modules.bar.widgets as W

// Time (bright) and date (dim), e.g. "01:48  SUN 27 SEP". Glows while the
// calendar is open.
Row {
    id: root

    required property W.Clock control

    spacing: 8

    W.BarLabel {
        text: Qt.formatDateTime(root.control.now, "HH:mm")
        color: root.control.active ? Theme.palette.accent : Theme.palette.fg
        lit: root.control.active
    }
    W.BarLabel {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(root.control.now, "ddd dd MMM")
        caps: true
        color: root.control.hovered || root.control.active ? Theme.palette.fg : Theme.palette.dim
        font.pixelSize: Theme.font.size - 1
        tracking: 1
    }
}
