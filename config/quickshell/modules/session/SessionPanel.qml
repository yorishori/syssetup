import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.services

// Session menu: lock, shutdown, reboot, sleep as big stacked keys.
// 1-4 or Up/Down select, Enter activates, Escape cancels / closes.
// Shutdown and reboot arm first: the key warns and a fuse burns for 3s
// before it runs (press again to go now, Escape to cancel). Lock is immediate;
// sleep locks first, then suspends.
ColumnLayout {
    id: root

    property bool open: false

    signal done

    property int selected: 0
    property int armed: -1

    readonly property var actions: [
        { label: "Lock", glyph: "\u{F033E}", confirm: false, run: () => Session.lock() },
        { label: "Shutdown", glyph: "\u{F0425}", confirm: true, run: () => Session.poweroff() },
        { label: "Reboot", glyph: "\u{F0709}", confirm: true, run: () => Session.reboot() },
        { label: "Sleep", glyph: "\u{F0904}", confirm: false, run: () => Session.suspend() }
    ]

    width: 300
    spacing: 10
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

    SectionTitle {
        text: "Session"
        code: `${Session.hostname} · up ${Session.uptimeText}`
    }

    Repeater {
        model: root.actions

        SessionKey {
            required property var modelData
            required property int index

            Layout.fillWidth: true
            label: armed ? "confirm?" : modelData.label
            glyph: modelData.glyph
            number: index + 1
            current: root.selected === index
            armed: root.armed === index
            onHoveredChanged: {
                if (hovered && root.armed !== index)
                    root.selected = index;
            }
            onClicked: root.activate(index)
            onFused: root.execute(index)
        }
    }

    KeyHints {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 2
        hints: [["1-4", "select"], ["↵", "confirm"], ["esc", "cancel"]]
    }
}
