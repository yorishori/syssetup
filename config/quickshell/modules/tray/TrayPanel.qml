import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.components

// A tray app's menu, drawn by us. Entries come from the app over D-Bus
// (QsMenuOpener); triggering one runs the app's own action. Submenus open in
// place, with a way back. Keyboard: Up/Down to move, Enter/Right to open or
// activate, Left/Backspace to go back, Escape to close. The skin (TrayMenu)
// lays it out.
//
// If the app's menu never loads, `fallback` asks the bar to show the native
// menu instead, so a quirky app is never unusable.
Skinned {
    id: root

    required property SystemTrayItem item
    property bool open: false

    signal done
    signal fallback

    // Submenu entries we've descended into; the menu shown is the last one.
    property var stack: []
    property int highlighted: -1

    readonly property var current: stack.length > 0 ? stack[stack.length - 1] : item?.menu ?? null
    // The entries shown (QsMenuEntry), as a model and as a list.
    readonly property var entryModel: opener.children
    readonly property var entries: opener.children.values
    readonly property string title: item ? (item.tooltipTitle || item.title || item.id) : ""
    readonly property string icon: item?.icon ?? ""
    // Where it is in the tray, counting from the first.
    readonly property int slot: SystemTray.items.values.indexOf(item)

    skin: "TrayMenu"
    focus: open

    function reset(): void {
        stack = [];
        highlighted = -1;
    }

    function activate(entry: var): void {
        if (!entry || entry.isSeparator || !entry.enabled)
            return;
        if (entry.hasChildren) {
            stack = [...stack, entry];
            highlighted = -1;
        } else {
            entry.triggered();
            done();
        }
    }

    function back(): void {
        if (stack.length > 0) {
            stack = stack.slice(0, -1);
            highlighted = -1;
        }
    }

    // Next selectable entry from the highlighted one in direction `step`.
    function move(step: int): void {
        for (let i = 1; i <= entries.length; i++) {
            const index = (highlighted + step * i + entries.length * 2) % entries.length;
            const entry = entries[index];
            if (!entry.isSeparator && entry.enabled) {
                highlighted = index;
                return;
            }
        }
    }

    // An entry's text without its mnemonic underscores.
    function label(entry: var): string {
        return (entry?.text ?? "").replace(/_(?!_)/g, "");
    }

    onItemChanged: reset()
    onOpenChanged: {
        reset();
        if (open) {
            forceActiveFocus();
            if (item && !item.hasMenu)
                done();
        }
    }

    Keys.onUpPressed: move(-1)
    Keys.onDownPressed: move(1)
    Keys.onReturnPressed: activate(entries[highlighted])
    Keys.onEnterPressed: activate(entries[highlighted])
    Keys.onRightPressed: activate(entries[highlighted])
    Keys.onLeftPressed: back()
    Keys.onEscapePressed: done()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Backspace)
            back();
    }

    QsMenuOpener {
        id: opener

        menu: root.current
    }

    // Menus load asynchronously; if nothing arrives, hand over to the native menu.
    Timer {
        interval: 1500
        running: root.open && root.entries.length === 0
        onTriggered: root.fallback()
    }
}
