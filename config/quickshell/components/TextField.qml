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

    // When set, Left/Right don't move the text cursor but emit horizontal()
    // (e.g. to move through a grid of results).
    property bool captureHorizontal: false
    property bool submitOnEnter: false

    signal accepted(int modifiers)
    signal horizontal(int step)
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
        Keys.onLeftPressed: event => {
            if (root.captureHorizontal)
                root.horizontal(-1);
            else
                event.accepted = false;
        }
        Keys.onRightPressed: event => {
            if (root.captureHorizontal)
                root.horizontal(1);
            else
                event.accepted = false;
        }
        onEditingFinished: root.editingFinished()
        Keys.onReturnPressed: event => root.enter(event.modifiers)
        Keys.onEnterPressed: event => root.enter(event.modifiers)
    }
}
