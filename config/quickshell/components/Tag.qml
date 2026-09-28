import QtQuick
import qs.core

// Small filled label, like a sticker on hardware: "REBOOT PENDING", app names.
Item {
    property alias text: label.text
    property color fill: Config.colors.warn
    property color textColor: Config.colors.shadow
    property int size: Config.font.size - 3

    implicitWidth: label.implicitWidth + 14
    implicitHeight: label.implicitHeight + 4

    Chamfer {
        anchors.fill: parent
        cut: 4
        fill: parent.fill
    }
    StyledText {
        id: label

        anchors.centerIn: parent
        color: parent.textColor
        font.pixelSize: parent.size
        font.bold: true
        font.letterSpacing: 1.5
    }
}
