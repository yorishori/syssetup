import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.components
import qs.core

// A tray app's menu, drawn by us. Entries come from the app over D-Bus
// (QsMenuOpener); triggering one runs the app's own action. Submenus open in
// place with a BACK row. Keyboard: Up/Down to move, Enter/Right to open or
// activate, Left/Backspace to go back, Escape to close.
//
// If the app's menu never loads, `fallback` asks the bar to show the native
// menu instead, so a quirky app is never unusable.
ColumnLayout {
    id: root

    required property SystemTrayItem item
    property bool open: false

    signal done
    signal fallback

    // Submenu entries we've descended into; the menu shown is the last one.
    property var stack: []
    property int highlighted: -1

    readonly property var current: stack.length > 0 ? stack[stack.length - 1] : item?.menu ?? null
    readonly property var entries: opener.children.values
    readonly property string title: item ? (item.tooltipTitle || item.title || item.id) : ""

    width: 260
    spacing: 4
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

    SectionTitle {
        text: root.title.toUpperCase()
        code: "TRAY"
    }

    // Back row inside submenus
    MenuRow {
        visible: root.stack.length > 0
        label: "BACK"
        glyph: "\u{F0141}"
        stencil: true
        onClicked: root.back()
    }

    Placeholder {
        text: "-- loading --"
        visible: root.entries.length === 0
    }

    Repeater {
        model: opener.children

        Item {
            id: entryItem

            required property QsMenuEntry modelData
            required property int index

            Layout.fillWidth: true
            implicitHeight: modelData.isSeparator ? 9 : 26

            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 12
                height: 1
                color: Config.colors.border
                visible: entryItem.modelData.isSeparator
            }

            MenuRow {
                anchors.fill: parent
                visible: !entryItem.modelData.isSeparator
                label: entryItem.modelData.text.replace(/_(?!_)/g, "")
                icon: entryItem.modelData.icon
                buttonType: entryItem.modelData.buttonType
                checked: entryItem.modelData.checkState === Qt.Checked
                submenu: entryItem.modelData.hasChildren
                enabled: entryItem.modelData.enabled
                current: root.highlighted === entryItem.index
                onEntered: root.highlighted = entryItem.index
                onClicked: root.activate(entryItem.modelData)
            }
        }
    }

    // One menu line: [lamp] [icon] label  [›]
    component MenuRow: ListRow {
        id: row

        property string label
        property string icon: ""
        property string glyph: ""
        property int buttonType: QsMenuButtonType.None
        property bool checked: false
        property bool submenu: false
        property bool stencil: false

        implicitHeight: 26
        leftPadding: 8
        rightPadding: 8
        spacing: 8
        marker: false

        // Checkbox: square lamp. Radio: small diamond lamp.
        Lamp {
            on: row.checked
            rotation: row.buttonType === QsMenuButtonType.RadioButton ? 45 : 0
            visible: row.buttonType !== QsMenuButtonType.None
        }
        IconImage {
            implicitSize: 14
            source: Icons.url(row.icon)
            visible: row.icon !== ""
        }
        StyledText {
            text: row.glyph
            color: Config.colors.dim
            visible: row.glyph !== ""
        }
        StyledText {
            Layout.fillWidth: true
            text: row.label
            elide: Text.ElideRight
            color: !row.enabled ? Config.colors.muted
                : row.checked ? Config.colors.accent
                : row.current || row.hovered ? Config.colors.fg
                : Config.colors.dim
            glow: row.checked && row.enabled
            font.pixelSize: row.stencil ? Config.font.size - 2 : Config.font.size
            font.bold: row.stencil
            font.letterSpacing: row.stencil ? 1.5 : 0
        }
        StyledText {
            text: "\u{F0142}"
            color: Config.colors.muted
            visible: row.submenu
        }
    }
}
