import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.services

// The session menu over the whole screen, bar included, for themes that
// show it that way (Theme.sessionScreen); the others drop it from the bar.
// It stays up while the skin still covers the screen (`covering`), so it
// can animate away.
PanelWindow {
    id: win

    readonly property bool open: Theme.sessionScreen && Panels.isOpen("session")

    screen: Display.primary
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: open || (menu.view?.covering ?? false)
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-session"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    SessionPanel {
        id: menu

        anchors.fill: parent
        open: win.open
        onDone: Panels.close()
    }
}
