import QtQuick
import qs.core

// Small square indicator lamp: lit (accent, or `color`) when `on`.
Rectangle {
    property bool on: false
    property color litColor: Config.colors.accent

    implicitWidth: 6
    implicitHeight: 6
    color: on ? litColor : Config.colors.surface
}
