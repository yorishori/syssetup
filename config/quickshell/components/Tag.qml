import QtQuick
import qs.core

// Small filled label: "REBOOT PENDING", app names, sizes.
Skinned {
    property string text
    property color fill: Theme.palette.warn
    property color textColor: Theme.palette.shadow
    property int size: Theme.font.size - 3

    skin: "Tag"
}
