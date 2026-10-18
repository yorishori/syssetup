import QtQuick
import qs.core

// Read-only gauge (e.g. battery): `value` 0..1 in `segments` steps.
Skinned {
    property real value: 0
    property int segments: 5
    property color color: Theme.palette.accent

    skin: "Gauge"
}
