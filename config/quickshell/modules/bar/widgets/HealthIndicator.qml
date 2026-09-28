import QtQuick
import qs.components
import qs.core

// Which parts of the shell are down, as a red warning tag. Hidden when all is
// fine; loud on purpose when not.
Item {
    visible: Health.count > 0
    implicitWidth: label.implicitWidth + 16
    implicitHeight: label.implicitHeight + 4

    Chamfer {
        anchors.fill: parent
        cut: 4
        fill: Config.colors.error
    }
    StyledText {
        id: label

        anchors.centerIn: parent
        text: "\u{F0026} " + Object.keys(Health.issues).join(" ").toUpperCase()
        color: Config.colors.shadow
        font.bold: true
        font.pixelSize: Config.font.size - 2
        font.letterSpacing: 1
    }
}
