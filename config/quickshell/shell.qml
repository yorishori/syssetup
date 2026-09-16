import Quickshell
import QtQuick
import Quickshell.Io

PanelWindow { // qmllint disable uncreatable-type
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 30

    Text {
        id: clock
        anchors.centerIn: parent
        Process {
            command: ["date"]
            running: true
            stdout: StdioCollector {
                onStreamFinished: clock.text = this.text
            }
        }
    }
}
