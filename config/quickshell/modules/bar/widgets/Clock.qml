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
            color: root.active ? Config.colors.accent : Config.colors.fg
            lit: root.active
        }
        BarLabel {
            anchors.verticalCenter: parent.verticalCenter
            text: Time.format("ddd dd MMM").toUpperCase()
            color: area.containsMouse || root.active ? Config.colors.fg : Config.colors.dim
            font.pixelSize: Config.font.size - 1
            font.letterSpacing: 1
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
