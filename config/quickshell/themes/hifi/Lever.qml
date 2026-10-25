import QtQuick

// A removable drive's pull lever: pulled, it swings out and the drive
// is let go.
Item {
    id: lever

    property real pull: 0

    signal pulled

    width: 34
    height: 28

    SequentialAnimation {
        id: pullOut

        NumberAnimation { target: lever; property: "pull"; to: 1; duration: 180; easing.type: Easing.OutCubic }
        ScriptAction { script: lever.pulled() }
        PauseAnimation { duration: 400 }
        NumberAnimation { target: lever; property: "pull"; to: 0; duration: 260; easing.type: Easing.InOutQuad }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 6
        height: 6
        radius: 3
        color: "#111113"
    }
    Item {
        anchors.centerIn: parent
        width: 30
        height: 8
        rotation: -38 * lever.pull
        transformOrigin: Item.Left

        Rectangle {
            anchors.fill: parent
            radius: 4
            border.width: 1
            border.color: "black"
            gradient: Gradient {
                GradientStop { position: 0; color: leverArea.containsMouse ? "#f0f1f4" : "#d4d6db" }
                GradientStop { position: 1; color: "#6a6c72" }
            }
        }
    }
    MouseArea {
        id: leverArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (!pullOut.running) pullOut.start()
    }
}
