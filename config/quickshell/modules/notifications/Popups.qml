import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core

// The window notification popups show in: the whole primary screen, over
// everything, click-through but for what the skin shows (PopupStack).
PanelWindow {
    screen: Display.primary
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    // Over the whole screen, the bar too (skins keep clear of it if they
    // want to, by the stack's barHeight), without reserving space ourselves.
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-notifications"
    color: "transparent"

    mask: Region {
        item: stack.view?.inputArea ?? null
    }

    PopupStack {
        id: stack

        anchors.fill: parent
    }
}
