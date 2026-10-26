import QtQuick
import QtQuick.Layouts
import qs.components as C
import qs.core

// A small-capital heading in lavender, a pixel line running on from it,
// and the code at the far end.
RowLayout {
    id: root

    required property C.SectionTitle control
    readonly property int px: Theme.get("pixel.scale") ?? 3

    spacing: 8

    C.StyledText {
        text: root.control.text
        caps: true
        color: Theme.palette.dim
        font.family: Theme.get("font.labels") ?? Theme.font.family
        font.pixelSize: Theme.font.size - 2
    }
    Rectangle {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        implicitHeight: root.px
        color: Theme.palette.surface
    }
    C.StyledText {
        text: root.control.code
        caps: true
        color: Theme.palette.muted
        font.family: Theme.get("font.labels") ?? Theme.font.family
        font.pixelSize: Theme.font.size - 3
        visible: root.control.code !== ""
    }
}
