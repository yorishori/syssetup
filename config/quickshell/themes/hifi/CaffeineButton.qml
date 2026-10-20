import QtQuick
import qs.core
import qs.modules.bar.widgets as W

// A toggle switch printed AWAKE: up holds the machine awake, its tip lit.
Row {
    id: root

    required property W.CaffeineButton control

    spacing: 5

    Toggle {
        on: root.control.on
        hovered: root.control.hovered
        tipLit: root.control.on
        tipColor: Theme.palette.warn
    }
    Legend {
        anchors.verticalCenter: parent.verticalCenter
        text: "awake"
        color: root.control.on ? Theme.palette.fg : Theme.palette.dim
    }
}
