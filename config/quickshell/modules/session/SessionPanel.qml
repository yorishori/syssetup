import QtQuick
import qs.components
import qs.services

// Session menu: lock, shutdown, reboot, sleep. The skin (SessionMenu) lays
// out a SessionKey per action and wires it here: hover(index) as the pointer
// moves over one, activate(index) on a click, execute(index) when its fuse
// runs out.
// 1-4 or Up/Down select, Enter activates, Escape cancels / closes.
// Shutdown and reboot arm first: the key warns and a fuse burns for 3s
// before it runs (press again to go now, Escape to cancel). Lock is immediate;
// sleep locks first, then suspends.
Skinned {
    id: root

    property bool open: false

    signal done

    property int selected: 0
    property int armed: -1

    // `key` names the action for skins that dress each one differently.
    readonly property var actions: [
        { key: "lock", label: "Lock", glyph: "\u{F033E}", confirm: false, run: () => Session.lock() },
        { key: "shutdown", label: "Shutdown", glyph: "\u{F0425}", confirm: true, run: () => Session.poweroff() },
        { key: "reboot", label: "Reboot", glyph: "\u{F0709}", confirm: true, run: () => Session.reboot() },
        { key: "sleep", label: "Sleep", glyph: "\u{F0904}", confirm: false, run: () => Session.suspend() }
    ]
    readonly property string hostname: Session.hostname
    readonly property string uptimeText: Session.uptimeText

    skin: "SessionMenu"
    focus: open

    function activate(index: int): void {
        selected = index;
        if (!actions[index].confirm || armed === index)
            execute(index);
        else
            armed = index;
    }

    function execute(index: int): void {
        armed = -1;
        done();
        actions[index].run();
    }

    function select(index: int): void {
        armed = -1;
        selected = (index + actions.length) % actions.length;
    }

    function hover(index: int): void {
        if (armed !== index)
            selected = index;
    }

    onOpenChanged: {
        armed = -1;
        selected = 0;
        if (open)
            forceActiveFocus();
    }

    Keys.onUpPressed: select(selected - 1)
    Keys.onDownPressed: select(selected + 1)
    Keys.onTabPressed: select(selected + 1)
    Keys.onReturnPressed: activate(selected)
    Keys.onEnterPressed: activate(selected)
    Keys.onEscapePressed: {
        if (armed >= 0)
            armed = -1;
        else
            done();
    }
    Keys.onPressed: event => {
        const n = event.key - Qt.Key_1;
        if (n >= 0 && n < actions.length)
            activate(n);
    }
}
