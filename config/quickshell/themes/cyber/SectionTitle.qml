import QtQuick
import QtQuick.Layouts
import qs.components as C
import qs.core

// Like a stencil on hardware:  ▌OUTPUT ────────── SINK
RowLayout {
    id: root

    required property C.SectionTitle control

    spacing: 6

    Rectangle {
        implicitWidth: 3
        implicitHeight: 10
        color: Theme.palette.accent
    }
    C.StyledText {
        text: root.control.text
        caps: true
        color: Theme.palette.dim
        font.pixelSize: Theme.font.size - 2
        font.bold: true
        tracking: 1.5
    }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Theme.palette.border
    }
    C.StyledText {
        text: root.control.code
        caps: true
        color: Theme.palette.muted
        font.pixelSize: Theme.font.size - 3
        tracking: 1
        visible: text !== ""
    }
}
