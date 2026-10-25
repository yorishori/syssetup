import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.core
import qs.services

// "Insert something" (SUPER+V): clipboard history, emoji, Nerd Font glyphs,
// symbols and kaomoji, over a darkened screen (ClipboardPicker; the theme
// draws it). Shift+Delete removes a history entry; a click outside closes.
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
    visible: Clipboard.open || backdrop.covering || (picker.view?.showing ?? false)
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-clipboard"
    WlrLayershell.keyboardFocus: Clipboard.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Shift+Delete removes the selected history entry (plain Delete edits the filter).
    Shortcut {
        sequence: "Shift+Delete"
        enabled: Clipboard.open && picker.onHistory
        onActivated: {
            const entry = picker.entries[picker.selected];
            if (entry)
                Clipboard.remove(entry);
        }
    }

    // Darkened, blurred backdrop; click to close.
    Backdrop {
        id: backdrop

        anchors.fill: parent
        shown: Clipboard.open

        MouseArea {
            anchors.fill: parent
            onClicked: Clipboard.hide()
        }
    }

    ClipboardPicker {
        id: picker

        anchors.fill: parent
    }
}
