import QtQuick
import qs.components
import qs.core
import qs.services

// Stop key, shown while a screen or voice recording runs: "■ 00:12" with
// what's being recorded. The privacy lamps stay pure indicators.
Item {
    id: root

    function duration(s: int): string {
        return `${String(Math.floor(s / 60)).padStart(2, "0")}:${String(s % 60).padStart(2, "0")}`;
    }

    visible: Capture.recording
    implicitWidth: row.implicitWidth + 16
    implicitHeight: 22

    Chamfer {
        anchors.fill: parent
        cut: 5
        fill: area.containsMouse ? Config.colors.warn : Qt.alpha(Config.colors.warn, 0.15)
        stroke: Config.colors.warn
    }
    Row {
        id: row

        anchors.centerIn: parent
        spacing: 6

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: "\u{F04DB}"
            color: area.containsMouse ? Config.colors.shadow : Config.colors.warn
            font.bold: true
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: `${Capture.kind === "voice" ? "VOICE" : "REC"} ${root.duration(Capture.elapsed)}`
            color: area.containsMouse ? Config.colors.shadow : Config.colors.warn
            font.pixelSize: Config.font.size - 2
            font.bold: true
            font.letterSpacing: 1
        }
    }
    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Capture.stop()
    }
}
