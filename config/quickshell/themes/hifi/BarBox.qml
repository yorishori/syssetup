import QtQuick
import qs.core
import qs.modules.bar.widgets as W

// A small glass window cut into the faceplate; lit from behind in its tone.
Item {
    id: root

    required property W.BarBox control
    readonly property bool toned: control.tone.a > 0

    Well {
        id: well

        anchors.fill: parent
        fill: root.toned ? Qt.tint(Theme.palette.bgAlt, Qt.alpha(root.control.tone, 0.14)) : Theme.palette.bgAlt
        ring: root.toned ? Qt.alpha(root.control.tone, 0.5) : "transparent"
    }
    Gloss {
        anchors {
            fill: parent
            margins: 1
        }
        roundness: well.r
    }
}
