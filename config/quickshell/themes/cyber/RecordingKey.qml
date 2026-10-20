import QtQuick
import qs.components as C
import qs.core
import qs.modules.bar.widgets as W

// "■ REC 00:12" on a peach-tinted key that fills on hover.
Item {
    id: root

    required property W.RecordingKey control
    readonly property bool shown: control.recording

    implicitWidth: row.implicitWidth + 16
    implicitHeight: 22

    Chamfer {
        anchors.fill: parent
        cut: 5
        fill: root.control.hovered ? Theme.palette.warn : Qt.alpha(Theme.palette.warn, 0.15)
        stroke: Theme.palette.warn
    }
    Row {
        id: row

        anchors.centerIn: parent
        spacing: 6

        C.StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: "\u{F04DB}"
            color: root.control.hovered ? Theme.palette.shadow : Theme.palette.warn
            font.bold: true
        }
        C.StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: `${root.control.label} ${root.control.elapsed}`
            caps: true
            color: root.control.hovered ? Theme.palette.shadow : Theme.palette.warn
            font.pixelSize: Theme.font.size - 2
            font.bold: true
            tracking: 1
        }
    }
}
