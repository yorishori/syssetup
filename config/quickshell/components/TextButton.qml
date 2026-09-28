import QtQuick
import qs.core

// Hardware key: cut-corner outline with a stencilled label. Lights up
// (accent fill) on hover and clicks down a pixel when pressed.
Item {
    id: root

    property string text
    property bool lit: false  // latched on (e.g. the active mode)

    signal clicked

    implicitWidth: label.implicitWidth + 22
    implicitHeight: label.implicitHeight + 10
    opacity: enabled ? 1 : 0.4

    Chamfer {
        anchors.fill: parent
        transform: Translate { y: area.pressed ? 1 : 0 }
        cut: 5
        fill: root.lit || area.containsMouse ? Config.colors.accent : Config.colors.bgAlt
        stroke: root.lit || area.containsMouse ? Config.colors.accent : Config.colors.border
    }

    StyledText {
        id: label

        anchors.centerIn: parent
        anchors.verticalCenterOffset: area.pressed ? 1 : 0
        text: root.text.toUpperCase()
        font.pixelSize: Config.font.size - 2
        font.bold: true
        font.letterSpacing: 1.5
        color: root.lit || area.containsMouse ? Config.colors.shadow : Config.colors.fg
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
