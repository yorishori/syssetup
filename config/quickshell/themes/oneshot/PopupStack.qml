import QtQuick
import Quickshell
import qs.components as C
import qs.core
import qs.modules.notifications as M

// Notifications top-right as letters (Letter), newest on top. They slide
// in from the side and out the same way, and pause their timeout while
// hovered. When one arrives the cat peeks over the top of it for a few
// seconds, then ducks back down (and back to the bar).
Item {
    id: root

    required property M.PopupStack control

    // Only the cards take input.
    readonly property Item inputArea: cardsArea

    Item {
        id: cardsArea

        anchors {
            top: list.top
            right: list.right
        }
        width: list.width
        height: Math.min(list.contentHeight, list.height)
    }

    ListView {
        id: list

        anchors {
            top: parent.top
            right: parent.right
            // Under the bar, with room for the cat to peek over the top one.
            topMargin: root.control.barHeight + 30
            rightMargin: Setup.bar.padding
        }
        width: 360
        height: parent.height - anchors.topMargin
        spacing: 10
        interactive: false

        model: ScriptModel {
            values: root.control.popups
        }

        delegate: Letter {
            id: card

            required property var modelData

            width: list.width
            app: modelData?.appName ?? ""
            summary: modelData?.summary ?? ""
            body: root.control.plain(modelData)
            when: "now"
            critical: root.control.critical(modelData)
            actions: (modelData?.actions ?? []).filter(a => a.identifier !== "default")
            onOpened: root.control.invoke(modelData)
            onDismissed: root.control.dismiss(modelData)

            Timer {
                interval: root.control.timeout(card.modelData) * 1000
                running: interval > 0 && !card.hovered
                onTriggered: root.control.hide(card.modelData)
            }
        }

        add: Transition {
            NumberAnimation { property: "x"; from: 48; to: 0; duration: 240; easing.type: Easing.OutCubic }
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 }
        }
        remove: Transition {
            NumberAnimation { property: "x"; to: 48; duration: 160; easing.type: Easing.InCubic }
            NumberAnimation { property: "opacity"; to: 0; duration: 160 }
        }
        // Cards pushed down glide to their place; one caught mid-entry is
        // finished off.
        displaced: Transition {
            NumberAnimation { property: "y"; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { property: "x"; to: 0; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { property: "opacity"; to: 1; duration: 150 }
        }
    }

    // The cat peeking over the newest card: it rises in steps, looks for a
    // while, and sinks back.
    Item {
        id: peek

        readonly property int px: Theme.get("pixel.scale") ?? 3
        // How many of its rows show: 0 (hidden) to 9 (up to its chin).
        property int rows: 0
        property bool up: false

        x: list.x + list.width - 26 * px
        // The newest card is always the top one.
        y: list.y - height
        width: 16 * px
        height: rows * px
        clip: true
        visible: rows > 0 && list.count > 0

        Cat {
            pose: "sit"
            flip: true
        }

        Timer {
            interval: 110
            repeat: true
            running: peek.rows !== (peek.up ? 9 : 0)
            onTriggered: peek.rows += peek.up ? 1 : -1
            onRunningChanged: if (!running && !peek.up) CatState.peeking = false
        }
        Timer {
            id: stay

            interval: 4000
            onTriggered: peek.up = false
        }

        function show(): void {
            CatState.peeking = true;
            up = true;
            stay.restart();
        }
    }

    property int seen: 0

    Connections {
        target: root.control

        function onPopupsChanged() {
            const n = root.control.popups.length;
            if (n > root.seen)
                peek.show();
            else if (n === 0)
                peek.up = false;
            root.seen = n;
        }
    }
}
