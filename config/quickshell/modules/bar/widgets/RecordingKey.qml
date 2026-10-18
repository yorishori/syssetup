import QtQuick
import qs.components
import qs.services

// Stop key, shown while a screen or voice recording runs: what's being
// recorded and for how long. Click stops it. The privacy lamps stay pure
// indicators.
Skinned {
    id: root

    readonly property string label: Capture.kind === "voice" ? "voice" : "rec"
    readonly property string elapsed: `${String(Math.floor(Capture.elapsed / 60)).padStart(2, "0")}:${String(Capture.elapsed % 60).padStart(2, "0")}`
    readonly property bool hovered: area.containsMouse

    skin: "RecordingKey"
    visible: Capture.recording

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Capture.stop()
    }
}
