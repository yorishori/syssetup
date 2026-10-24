import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// What to do with a capture, at the bottom edge of the screen: SAVE (Enter),
// SAVE + COPY, COPY (screenshots), DISCARD (Escape). Nothing is kept until
// one is chosen. The skin (SavePrompt) draws it.
PanelWindow {
    id: win

    readonly property bool asking: Capture.state === "asking"

    screen: Display.primary
    anchors.bottom: true
    implicitWidth: prompt.implicitWidth
    implicitHeight: 420
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: asking || (prompt.view?.showing ?? false)
    mask: Region {
        item: prompt.view?.inputArea ?? null
    }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-capture-prompt"
    WlrLayershell.keyboardFocus: asking ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    SavePrompt {
        id: prompt

        anchors.fill: parent
    }
}
