import QtQuick
import QtQuick.Layouts
import qs.core

// Panel section label, like a stencil on hardware:  ▌OUTPUT ────────── SINK
RowLayout {
    property alias text: label.text
    property string code: ""

    Layout.fillWidth: true
    spacing: 6

    Rectangle {
        implicitWidth: 3
        implicitHeight: 10
        color: Config.colors.accent
    }
    StyledText {
        id: label

        color: Config.colors.dim
        font.pixelSize: Config.font.size - 2
        font.bold: true
        font.letterSpacing: 1.5
    }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Config.colors.border
    }
    StyledText {
        text: parent.code
        color: Config.colors.muted
        font.pixelSize: Config.font.size - 3
        font.letterSpacing: 1
        visible: text !== ""
    }
}
