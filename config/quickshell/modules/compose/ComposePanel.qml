import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Compose overlay (bind it to the compose key): see ComposePad; the theme
// draws it. A click outside closes.
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
    visible: Compose.open || (pad.view?.showing ?? false)
    mask: Region {
        item: Compose.open ? fullArea : (pad.view?.inputArea ?? null)
    }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-compose"
    WlrLayershell.keyboardFocus: Compose.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Click outside the drawer closes.
    Item {
        id: fullArea

        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            onClicked: Panels.close()
        }
    }

    ComposePad {
        id: pad

        anchors.fill: parent
    }
}
