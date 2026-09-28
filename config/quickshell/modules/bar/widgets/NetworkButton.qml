import QtQuick
import qs.core
import qs.services

// Connection at a glance: ethernet when wired, Wi-Fi bars by signal strength.
// Dim when online, peach (pulsing while connecting) when not, dim red when
// Wi-Fi is off.
// Click opens the network drop.
BarLabel {
    id: root

    signal toggleDrop

    readonly property bool connecting: Network.state === "connecting" || Network.pending !== ""
    readonly property bool online: Network.wiredConnected || Network.connected !== null

    text: {
        if (Network.wiredConnected)
            return "\u{F0200}";
        if (!Network.wifiEnabled)
            return "\u{F092E}";
        const s = Network.connected?.strength ?? -1;
        return s >= 75 ? "\u{F0928}"
            : s >= 50 ? "\u{F0925}"
            : s >= 25 ? "\u{F0922}"
            : s >= 0 ? "\u{F091F}"
            : "\u{F092F}";
    }
    color: online ? Config.colors.dim
        : !Network.wifiEnabled ? Config.colors.off
        : Config.colors.warn

    Behavior on color {
        ColorAnimation { duration: 250 }
    }

    SequentialAnimation on opacity {
        running: root.connecting
        loops: Animation.Infinite
        alwaysRunToEnd: true

        NumberAnimation { to: 0.35; duration: 600; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutSine }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleDrop()
    }
}
