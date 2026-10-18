import QtQuick
import qs.core

// Indicator lamp: lit (accent, or `litColor`) when `on`; `pulse` makes it
// throb (something is live, e.g. recording).
Skinned {
    property bool on: false
    property color litColor: Theme.palette.accent
    property bool pulse: false

    skin: "Lamp"
}
