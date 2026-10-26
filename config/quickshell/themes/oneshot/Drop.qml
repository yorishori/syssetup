import QtQuick
import qs.components
import qs.core
import qs.modules.bar as B

// An RPG window that unrolls below the bar in four steps, the way old menus
// opened; its contents appear once it's fully open. Two sparkles twinkle on
// its corners.
Item {
    id: root

    required property B.Drop control

    readonly property real overhang: 0
    readonly property real inset: 6
    readonly property int px: Theme.get("pixel.scale") ?? 3
    readonly property int steps: 4
    property int step: 0

    // The window's name on top, the contents moved down under it.
    readonly property string title: Theme.get(`titles.${control.name}`) ?? ""
    readonly property real titleHeight: title !== "" ? 34 : 0
    readonly property real contentShift: titleHeight

    readonly property real shownHeight: step >= steps ? control.openHeight + titleHeight
        : Math.round((control.openHeight + titleHeight) * step / steps / px) * px
    readonly property real contentOpacity: step >= steps ? 1 : 0

    Timer {
        interval: 45
        repeat: true
        running: root.step !== (root.control.open ? root.steps : 0)
        onTriggered: root.step += root.control.open ? 1 : -1
    }

    Ticker { id: clock }

    Frame {
        anchors.fill: parent
    }

    StyledText {
        x: root.control.padding
        y: root.control.padding - 4
        text: root.title
        visible: root.title !== "" && root.step >= root.steps
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
            visible: root.step >= root.steps
            opacity: (clock.frame + modelData[2]) % 12 < 2 ? 0.25 : 0.9
        }
    }
}
