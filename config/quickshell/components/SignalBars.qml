import QtQuick
import qs.core

// Signal strength (0-100).
Skinned {
    property int strength: 0
    property color color: Theme.palette.fg

    skin: "SignalBars"
}
