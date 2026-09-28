import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.core
import qs.services

// Notification popups, top-right of the primary screen, newest on top.
// They bounce in, slide out, and pause their timeout while hovered.
PanelWindow {
    screen: Display.primary
    anchors {
        top: true
        right: true
        bottom: true
    }
    implicitWidth: list.width + list.anchors.rightMargin
    // Stay below the bar (and other panels) without reserving space ourselves.
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-notifications"
    color: "transparent"

    // Only the cards take input; the rest of the window is click-through.
    mask: Region {
        item: cardsArea
    }

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
            topMargin: 6
            rightMargin: Config.bar.padding
        }
        width: 360
        height: parent.height - anchors.topMargin
        spacing: 10
        interactive: false

        model: ScriptModel {
            values: Notifs.popups
        }

        delegate: NotificationCard {
            id: card

            required property var modelData

            notif: modelData
            onDismissRequested: Notifs.dismiss(modelData)

            Timer {
                interval: Notifs.popupTimeout(card.modelData) * 1000
                running: interval > 0 && !card.hovered
                onTriggered: Notifs.hidePopup(card.modelData)
            }
        }

        add: Transition {
            NumberAnimation { property: "x"; from: 400; duration: 450; easing.type: Easing.OutBack }
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
        }
        remove: Transition {
            NumberAnimation { property: "x"; to: 400; duration: 300; easing.type: Easing.InBack }
            NumberAnimation { property: "opacity"; to: 0; duration: 300 }
        }
        // Also finish any interrupted add animation (x, opacity), or a card
        // pushed down mid-entry stays half-transparent.
        displaced: Transition {
            NumberAnimation { property: "y"; duration: 350; easing.type: Easing.OutBack }
            NumberAnimation { property: "x"; to: 0; duration: 300; easing.type: Easing.OutBack }
            NumberAnimation { property: "opacity"; to: 1; duration: 200 }
        }
    }
}
