import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.services

// Session menu: lock, shutdown, reboot, sleep as big stacked keys.
// 1-4 or Up/Down select, Enter activates, Escape cancels / closes.
// Shutdown and reboot arm first: the key turns peach and a fuse burns for 3s
// before it runs (press again to go now, Escape to cancel). Lock is immediate;
// sleep locks first, then suspends.
ColumnLayout {
    id: root

    property bool open: false

    signal done

    property int selected: 0
    property int armed: -1

    readonly property var actions: [
        { label: "LOCK", glyph: "\u{F033E}", confirm: false, run: () => Session.lock() },
        { label: "SHUTDOWN", glyph: "\u{F0425}", confirm: true, run: () => Session.poweroff() },
        { label: "REBOOT", glyph: "\u{F0709}", confirm: true, run: () => Session.reboot() },
        { label: "SLEEP", glyph: "\u{F0904}", confirm: false, run: () => Session.suspend() }
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
        text: "SESSION"
        code: `${Session.hostname.toUpperCase()} · UP ${Session.uptimeText}`
    }

    Repeater {
        model: root.actions

        Item {
            id: key

            required property var modelData
            required property int index
            readonly property bool current: root.selected === index
            readonly property bool isArmed: root.armed === index
            readonly property color tone: isArmed ? Config.colors.warn : Config.colors.accent

            Layout.fillWidth: true
            implicitHeight: 76
            scale: keyArea.pressed ? 0.97 : 1

            Behavior on scale {
                NumberAnimation { duration: 180; easing.type: Easing.OutBack }
            }

            Chamfer {
                anchors.fill: parent
                cut: 10
                fill: key.isArmed ? Qt.alpha(Config.colors.warn, 0.12) : key.current ? Config.colors.surface : Config.colors.bgAlt
                stroke: key.current || key.isArmed ? key.tone : Config.colors.border
                strokeWidth: key.current || key.isArmed ? 2 : 1
            }

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 20
                    rightMargin: 18
                }
                spacing: 18

                StyledText {
                    text: key.modelData.glyph
                    color: key.current || key.isArmed ? key.tone : Config.colors.dim
                    glow: key.current || key.isArmed
                    font.pixelSize: 38
                }
                StyledText {
                    Layout.fillWidth: true
                    text: key.isArmed ? "CONFIRM?" : key.modelData.label
                    color: key.current || key.isArmed ? Config.colors.fg : Config.colors.dim
                    font.pixelSize: Config.font.size + 5
                    font.bold: true
                    font.letterSpacing: 3
                }
                // Index code, like a label on a hardware key.
                StyledText {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 10
                    text: String(key.index + 1).padStart(2, "0")
                    color: key.current ? key.tone : Config.colors.muted
                    font.pixelSize: Config.font.size - 2
                    font.bold: true
                }
            }

            // Armed: a fuse burns for 3s, then the action runs.
            Rectangle {
                anchors {
                    left: parent.left
                    bottom: parent.bottom
                    leftMargin: 14
                    bottomMargin: 10
                }
                height: 3
                width: 0
                color: Config.colors.warn
                visible: key.isArmed

                NumberAnimation on width {
                    running: key.isArmed
                    from: key.width - 28
                    to: 0
                    duration: 3000
                    onFinished: {
                        if (key.isArmed)
                            root.execute(key.index);
                    }
                }
            }

            MouseArea {
                id: keyArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                    if (root.armed !== key.index)
                        root.selected = key.index;
                }
                onClicked: root.activate(key.index)
            }
        }
    }

    KeyHints {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 2
        hints: [["1-4", "select"], ["↵", "confirm"], ["esc", "cancel"]]
    }
}
