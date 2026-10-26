import QtQuick
import qs.components
import qs.core
import qs.modules.bar as B

// An RPG window that unrolls below the bar, easing open; its contents fade
// in as it finishes. Two sparkles twinkle on its corners.
Item {
    id: root

    required property B.Drop control

    readonly property real overhang: 0
    readonly property real inset: 6
    readonly property int px: Theme.get("pixel.scale") ?? 3
    // 0 shut to 1 open, eased (the frame moves smoothly; only the art's
    // idle loops step).
    property real progress: control.open ? 1 : 0

    Behavior on progress {
        NumberAnimation {
            duration: root.control.open ? 240 : 150
            easing.type: root.control.open ? Easing.OutCubic : Easing.InCubic
        }
    }

    // The window's name on top, the contents moved down under it.
    readonly property string title: Theme.get(`titles.${control.name}`) ?? ""
    readonly property real titleHeight: title !== "" ? 34 : 0
    readonly property real contentShift: titleHeight

    readonly property real shownHeight: (control.openHeight + titleHeight) * progress
    // The contents (and title, sparkles) fade in over the last stretch.
    readonly property real contentOpacity: Math.max(0, (progress - 0.6) / 0.4)

    Ticker { id: clock }

    Frame {
        anchors.fill: parent
    }

    StyledText {
        x: root.control.padding
        y: root.control.padding - 4
        text: root.title
        visible: root.title !== ""
        opacity: root.contentOpacity
        color: Theme.palette.accent
        font.pixelSize: Theme.font.size + 6
        font.weight: Font.DemiBold
    }

    Repeater {
        model: [[-1, -1, 0], [1, 1, 5]]

        PixelArt {
            required property var modelData

            x: modelData[0] < 0 ? -root.px : root.width - 2 * root.px
            y: modelData[1] < 0 ? -root.px : root.height - 2 * root.px
            px: root.px
            colors: ({ "s": Theme.palette.accent })
            rows: [".s.", "sss", ".s."]
            opacity: root.contentOpacity * ((clock.frame + modelData[2]) % 12 < 2 ? 0.25 : 0.9)
        }
    }
}
