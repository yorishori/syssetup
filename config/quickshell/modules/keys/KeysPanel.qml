import QtQuick
import qs.components
import qs.services

// Keyboard shortcuts cheat sheet (SUPER+F1): Sway's binds by section. Read
// from the loaded config every time it opens (see Keybinds). Escape closes;
// Up/Down scroll. The skin (KeysMenu) lays it out.
Skinned {
    id: root

    property bool open: false
    property real maxHeight: 900

    // Up/Down: scroll by this flick velocity.
    signal nudged(real velocity)

    readonly property var groups: Keybinds.groups
    readonly property string error: Keybinds.error
    readonly property int count: Keybinds.count

    skin: "KeysMenu"
    focus: open

    // The sections split into `count` contiguous columns of about equal
    // height, a section's height given by `size`.
    function split(count: int, size: var): var {
        const target = groups.reduce((n, g) => n + size(g), 0) / count;
        const out = [[]];
        let height = 0;
        for (const g of groups) {
            if (height > 0 && height + size(g) / 2 > target && out.length < count) {
                out.push([]);
                height = 0;
            }
            out[out.length - 1].push(g);
            height += size(g);
        }
        return out;
    }

    function dismiss(): void {
        Panels.close();
    }

    onOpenChanged: {
        if (open)
            forceActiveFocus();
    }

    Keys.onEscapePressed: dismiss()
    Keys.onUpPressed: nudged(800)
    Keys.onDownPressed: nudged(-800)
}
