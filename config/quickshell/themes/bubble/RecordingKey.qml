import QtQuick
import qs.components as C
import qs.core
import qs.modules.bar.widgets as W

// "● rec 00:12" on a peach-tinted pill that fills on hover.
Item {
    id: root

    required property W.RecordingKey control

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 22

    Box {
        anchors.fill: parent
        roundness: height / 2
        fill: root.control.hovered ? Theme.palette.warn : Qt.alpha(Theme.palette.warn, 0.18)
    }
    Row {
        id: row

        anchors.centerIn: parent
        spacing: 6

        C.StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: "\u{F04DB}"
            color: root.control.hovered ? Theme.palette.shadow : Theme.palette.warn
        }
        C.StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: `${root.control.label} ${root.control.elapsed}`
            color: root.control.hovered ? Theme.palette.shadow : Theme.palette.warn
            font.pixelSize: Theme.font.size - 2
            font.bold: true
        }
    }
}
