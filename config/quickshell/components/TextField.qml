import QtQuick
import qs.core

// Single-line input with a `prompt` and a `placeholder`.
// For settings-style fields: submitOnEnter makes Enter leave the field (which
// ends editing, like clicking away), and flash() confirms a save for a moment.
//
// The skin draws everything around the text and tells the input where to sit
// (inputLeft / inputRight), how to color it (textColor, selectionColor,
// selectedTextColor) and what cursor to use (cursor: Component).
Skinned {
    id: root

    property alias text: input.text
    property alias echoMode: input.echoMode
    property string placeholder
    property string prompt: ">"
    readonly property bool inputFocused: input.activeFocus
    readonly property bool flashing: saved.running
    readonly property real inputHeight: input.implicitHeight

    // Sees each key before the field does: (key, modifiers) => true when it
    // takes it (a panel's fieldKey, so arrows can move through results).
    property var keyFilter: null
    property bool submitOnEnter: false

    signal accepted(int modifiers)
    signal editingFinished  // Enter pressed or focus left

    function focusInput(): void {
        input.forceActiveFocus();
    }

    function flash(): void {
        saved.restart();
    }

    function enter(modifiers: int): void {
        root.accepted(modifiers);
        if (submitOnEnter)
            root.forceActiveFocus();  // keys now go to the panel (Escape closes it)
    }

    skin: "TextField"

    Timer {
        id: saved

        interval: 1200
    }

    TextInput {
        id: input

        anchors.verticalCenter: parent.verticalCenter
        x: root.view?.inputLeft ?? 0
        width: root.width - x - (root.view?.inputRight ?? 0)
        color: root.view?.textColor ?? Theme.palette.fg
        selectionColor: root.view?.selectionColor ?? Theme.palette.accent
        selectedTextColor: root.view?.selectedTextColor ?? Theme.palette.bg
        cursorDelegate: root.view?.cursor ?? null
        font.family: Theme.font.family
        font.pixelSize: Theme.font.size
        clip: true
        Keys.onPressed: event => event.accepted = root.keyFilter?.(event.key, event.modifiers) ?? false
        onEditingFinished: root.editingFinished()
        // Return/Enter get their own signals, which Keys emits before
        // onPressed (and onPressed not at all once they take the key), so
        // they ask keyFilter first themselves.
        Keys.onReturnPressed: event => {
            if (!root.keyFilter?.(event.key, event.modifiers))
                root.enter(event.modifiers);
        }
        Keys.onEnterPressed: event => {
            if (!root.keyFilter?.(event.key, event.modifiers))
                root.enter(event.modifiers);
        }
    }
}
