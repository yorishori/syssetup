import QtQuick
import qs.components as C
import qs.core
import qs.modules.bar.widgets as W

// A red warning tag naming what's down. Hidden when all is fine; loud on
// purpose when not.
C.Tag {
    required property W.HealthIndicator control
    readonly property bool shown: control.issues.length > 0

    text: "\u{F0026} " + control.issues.join(" ")
    fill: Theme.palette.error
    size: Theme.font.size - 2
}
