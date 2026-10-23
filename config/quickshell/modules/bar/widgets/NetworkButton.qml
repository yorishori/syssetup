import QtQuick
import qs.components
import qs.services

// The connection: wired, Wi-Fi (with its signal `strength`, 0-100), coming
// up, or none; whether the Wi-Fi radio is on. Click opens the network drop.
Skinned {
    id: root

    readonly property bool wired: Network.wiredConnected
    readonly property bool wifiEnabled: Network.wifiEnabled
    readonly property int strength: Network.connected?.strength ?? -1
    readonly property bool connecting: Network.state === "connecting" || Network.pending !== ""
    readonly property bool online: wired || Network.connected !== null
    readonly property bool hovered: area.containsMouse

    signal toggleDrop

    skin: "NetworkButton"

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleDrop()
    }
}
