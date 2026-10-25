import QtQuick
import qs.components
import qs.services

// Stop key for a screen or voice recording: what's being recorded and for
// how long (`elapsed`, "mm:ss"; `seconds`). Click stops it. The skin may hide
// it while nothing records (`shown`).
Skinned {
    id: root

    readonly property bool recording: Capture.recording
    readonly property string label: Capture.kind === "voice" ? "voice" : "rec"
    readonly property int seconds: recording ? Capture.elapsed : 0
    readonly property string elapsed: `${String(Math.floor(seconds / 60)).padStart(2, "0")}:${String(seconds % 60).padStart(2, "0")}`
    readonly property bool hovered: area.containsMouse

    skin: "RecordingKey"
    visible: view?.shown ?? true

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.recording ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (root.recording)
                Capture.stop();
        }
    }
}
