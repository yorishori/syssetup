import QtQuick
import qs.core
import qs.modules.bar.widgets as W

// An illuminated rocker labelled AWAKE: on holds the machine awake, its lens
// lit amber.
Row {
    id: root

    required property W.CaffeineButton control

    spacing: 5

    Rocker {
        on: root.control.on
        hovered: root.control.hovered
        lit: root.control.on
        lampColor: Theme.palette.warn
    }
    Legend {
        anchors.verticalCenter: parent.verticalCenter
        text: "awake"
    }
}
