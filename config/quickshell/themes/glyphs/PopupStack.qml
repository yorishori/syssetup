import QtQuick
import Quickshell
import qs.components as C
import qs.core
import qs.modules.notifications as M

// Notification cards top-right, newest on top. They bounce in, slide out,
// and pause their timeout while hovered.
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
            // Just under the bar.
            topMargin: root.control.barHeight + 6
            rightMargin: Setup.bar.padding
        }
        width: 360
        height: parent.height - anchors.topMargin
        spacing: 10
        interactive: false

        model: ScriptModel {
            values: root.control.popups
        }

        delegate: C.NotificationCard {
            id: card

            required property var modelData

            notif: modelData
            onDismissRequested: root.control.dismiss(modelData)

            Timer {
                interval: root.control.timeout(card.modelData) * 1000
                running: interval > 0 && !card.hovered
                onTriggered: root.control.hide(card.modelData)
            }
        }

        add: Transition {
            NumberAnimation { property: "x"; from: 400; duration: 450; easing.type: Theme.motion.spring; easing.overshoot: Theme.motion.bounce }
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
        }
        remove: Transition {
            NumberAnimation { property: "x"; to: 400; duration: 300; easing.type: Theme.motion.springIn; easing.overshoot: Theme.motion.bounce }
            NumberAnimation { property: "opacity"; to: 0; duration: 300 }
        }
        // Also finish any interrupted add animation (x, opacity), or a card
        // pushed down mid-entry stays half-transparent.
        displaced: Transition {
            NumberAnimation { property: "y"; duration: 350; easing.type: Theme.motion.spring; easing.overshoot: Theme.motion.bounce }
            NumberAnimation { property: "x"; to: 0; duration: 300; easing.type: Theme.motion.spring; easing.overshoot: Theme.motion.bounce }
            NumberAnimation { property: "opacity"; to: 1; duration: 200 }
        }
    }
}
