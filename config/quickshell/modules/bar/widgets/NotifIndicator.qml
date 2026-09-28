import QtQuick
import qs.core
import qs.services

// Bell: dim when empty, accent with a count when something is waiting,
// dim red and crossed out in do-not-disturb. Click: open the notification
// center, right click: toggle do-not-disturb.
BarLabel {
    id: root

    property bool active: false
    readonly property int count: Notifs.list.length

    signal clicked

    text: Notifs.dnd ? "\u{F009B}" : count > 0 ? `\u{F009A} ${count}` : "\u{F009A}"
    lit: active || (!Notifs.dnd && count > 0)
    color: Notifs.dnd ? Config.colors.off : lit ? Config.colors.accent : Config.colors.dim

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                Notifs.setDnd(!Notifs.dnd, 0);
            else
                root.clicked();
        }
    }
}
