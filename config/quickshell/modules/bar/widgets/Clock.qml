import QtQuick
import qs.core
import qs.services

// Time (bright) and date (dim), e.g. "01:48  SUN 27 SEP". Click opens the
// calendar drop; glows while it's open.
Item {
    id: root

    property bool active: false

    signal clicked

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row

        spacing: 8

        BarLabel {
            text: Time.format("HH:mm")
            color: root.active ? Theme.palette.accent : Theme.palette.fg
            lit: root.active
        }
        BarLabel {
            anchors.verticalCenter: parent.verticalCenter
            text: Time.format("ddd dd MMM")
            caps: true
            color: area.containsMouse || root.active ? Theme.palette.fg : Theme.palette.dim
            font.pixelSize: Theme.font.size - 1
            tracking: 1
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
