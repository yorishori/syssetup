import QtQuick
import QtQuick.Layouts
import qs.components as C
import qs.core

// A small-capital heading in lavender, a pixel line running on from it,
// and the code at the far end. A heading that only repeats the window's
// amber title (Spec titles: "Settings" in Settings) leaves its name out
// and keeps just the code.
RowLayout {
    id: root

    required property C.SectionTitle control
    readonly property int px: Theme.get("pixel.scale") ?? 3
    readonly property bool repeat: Object.values(Theme.get("titles") ?? {})
        .some(t => String(t).toLowerCase() === root.control.text.toLowerCase())

    spacing: 8

    C.StyledText {
        text: root.control.text
        caps: true
        color: Theme.palette.dim
        font.family: Theme.get("font.labels") ?? Theme.font.family
        font.pixelSize: Theme.font.size - 2
        visible: !root.repeat
    }
    Rectangle {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        implicitHeight: root.px
        color: Theme.palette.surface
        opacity: root.repeat ? 0 : 1
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
