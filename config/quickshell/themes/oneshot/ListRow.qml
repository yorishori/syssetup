import QtQuick
import qs.components as C
import qs.core

// A raised plum band on hover and selection; the keyboard selection gets
// the RPG cursor, a little amber arrow that bobs.
Item {
    id: root

    required property C.ListRow control
    readonly property int px: Theme.get("pixel.scale") ?? 3

    Ticker { id: clock }

    Rectangle {
        anchors.fill: parent
        color: root.control.current || root.control.highlighted ? Theme.palette.surface
            : root.control.hovered && root.control.enabled ? Qt.alpha(Theme.palette.surface, 0.55)
            : "transparent"
    }
    PixelArt {
        x: clock.frame % 4 < 2 ? 0 : root.px
        anchors.verticalCenter: parent.verticalCenter
        px: 2
        colors: ({ "a": Theme.palette.accent })
        rows: ["a...", "aa..", "aaa.", "aaaa", "aaa.", "aa..", "a..."]
        visible: root.control.marker && root.control.current
    }
}
