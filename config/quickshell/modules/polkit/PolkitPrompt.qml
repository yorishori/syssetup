import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services

// Admin password prompt for polkit, over a darkened screen: see PolkitAsk;
// the theme draws it. Clicking anywhere puts the focus back in it.
PanelWindow {
    id: win

    screen: Display.primary
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: Polkit.active
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-polkit"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Backdrop {
        anchors.fill: parent
        strong: true

        MouseArea {
            anchors.fill: parent
            onClicked: ask.refocus()
        }
    }

    PolkitAsk {
        id: ask

        anchors.fill: parent
    }
}
