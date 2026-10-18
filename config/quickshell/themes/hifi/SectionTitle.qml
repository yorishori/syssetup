import QtQuick
import QtQuick.Layouts
import qs.components as C
import qs.core

// A silk-screened heading with a groove running from it; the code reads out
// on a small glass display at the far end.
RowLayout {
    id: root

    required property C.SectionTitle control

    spacing: 10

    Engraved {
        text: root.control.text
        caps: true
        tracking: 1.5
        color: Theme.palette.dim
        font.pixelSize: Theme.font.size - 1
        font.bold: true
    }
    Item {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        implicitHeight: 2

        Rectangle {
            width: parent.width
            height: 1
            color: Qt.alpha(Theme.palette.shadow, 0.8)
        }
        Rectangle {
            y: 1
            width: parent.width
            height: 1
            color: Qt.alpha("white", 0.08)
        }
    }
    Item {
        implicitWidth: code.implicitWidth + 14
        implicitHeight: code.implicitHeight + 4
        visible: root.control.code !== ""

        Well {
            anchors.fill: parent
            roundness: 3
        }
        C.StyledText {
            id: code

            anchors.centerIn: parent
            text: root.control.code
            caps: true
            color: Theme.palette.accent
            glow: true
            font.pixelSize: Theme.font.size - 3
            font.bold: true
        }
    }
}
