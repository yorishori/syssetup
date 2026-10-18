import QtQuick
import qs.core

// A small mark that points something out: the current workspace, the playing
// player, a calendar's color next to its event. Give it its size; `vertical`
// when it's taller than wide.
Skinned {
    property color color: Theme.palette.accent
    property bool vertical: false

    skin: "Marker"
}
