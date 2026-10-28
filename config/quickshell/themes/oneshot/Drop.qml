import QtQuick
import qs.components
import qs.core
import qs.modules.bar as B

// An RPG window conjured under the bar: stars pop at the point under its key,
// then it grows out of that point with stars riding its edges, and its
// contents fade in as it settles. Closing runs it backwards: it shrinks to
// the point, the last stars wink out. It hangs a little below the bar, more
// for the ones whose frames have ears or a mantel to show. Its frame is
// dressed for what it holds (see Frame); plain ones get two sparkles
// twinkling on their corners.
Item {
    id: root

    required property B.Drop control

    readonly property int px: Theme.get("pixel.scale") ?? 3
    // Room for what the frame fixes to its sides (a spine, whiskers, a mantel).
    readonly property real overhang: 10 * px
    // Off the screen's edge for the flush ones, and below the bar for all.
    readonly property var gaps: ({ control: [40, 36], session: [30, 30] })
    readonly property real inset: gaps[control.name]?.[0] ?? 6
    readonly property real gap: gaps[control.name]?.[1] ?? 18

    // 0 shut to 1 open, at an even pace; what moves takes its own curve
    // from it.
    property real progress: control.open ? 1 : 0

    Behavior on progress {
        NumberAnimation {
            duration: root.control.open ? 460 : 340
        }
    }

    // How far grown: nothing while the stars gather, then out of the point
    // with a little overshoot.
    readonly property real spread: {
        const t = Math.max(0, (progress - conjure.gather) / (1 - conjure.gather));
        const c = 1.3, u = t - 1;
        return t <= 0 ? 0 : 1 + (c + 1) * u * u * u + c * u * u;
    }
    readonly property real popScale: Math.max(0.04, spread)

    // The window's name on top, the contents moved down under it.
    readonly property string title: Theme.get(`titles.${control.name}`) ?? ""
    readonly property real titleHeight: title !== "" ? 34 : 0
    readonly property real contentShift: gap + titleHeight

    readonly property real shownHeight: progress > 0 ? control.openHeight + gap + titleHeight : 0
    // The contents (and title, sparkles) fade in as it settles.
    readonly property real contentOpacity: Math.max(0, (progress - 0.75) / 0.25)

    Ticker { id: clock }

    Item {
        id: window

        y: root.gap
        width: root.width
        height: root.height - root.gap
        opacity: Math.min(1, root.spread * 6)

        Frame {
            id: frame

            anchors.fill: parent
            kind: root.control.name
            trim: root.contentOpacity
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
            model: frame.dressed ? [] : [[-1, -1, 0], [1, 1, 5]]

            PixelArt {
                required property var modelData

                x: modelData[0] < 0 ? -root.px : window.width - 2 * root.px
                y: modelData[1] < 0 ? -root.px : window.height - 2 * root.px
                px: root.px
                colors: ({ "s": Theme.palette.accent })
                rows: [".s.", "sss", ".s."]
                opacity: root.contentOpacity * ((clock.frame + modelData[2]) % 12 < 2 ? 0.25 : 0.9)
            }
        }
    }

    Conjure {
        id: conjure

        progress: root.progress
        spread: root.spread
        originX: root.width / 2
        originY: 0
        targetWidth: root.width
        targetHeight: root.height
    }
}
