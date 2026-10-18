import QtQuick
import QtQuick.Layouts
import qs.components as C
import qs.core

// A quiet heading, with the code in a little pill on the far side.
RowLayout {
    id: root

    required property C.SectionTitle control

    spacing: 8

    C.StyledText {
        text: root.control.text
        caps: true
        color: Theme.palette.fg
        font.pixelSize: Theme.font.size - 1
        font.bold: true
    }
    Item {
        Layout.fillWidth: true
        implicitHeight: 1
    }
    Rectangle {
        implicitWidth: code.implicitWidth + 14
        implicitHeight: code.implicitHeight + 4
        radius: height / 2
        color: Theme.palette.surface
        visible: root.control.code !== ""

        C.StyledText {
            id: code

            anchors.centerIn: parent
            text: root.control.code
            caps: true
            color: Theme.palette.dim
            font.pixelSize: Theme.font.size - 3
        }
    }
}
