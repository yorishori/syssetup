import QtQuick
import Quickshell.Io

// Every message a D-Bus name sends, one line each (gdbus monitor). Kept
// running: brought back when it exits, waiting longer each time it dies
// straight away (gdbus missing, no bus) so it doesn't spin.
Process {
    id: root

    required property string dest
    property bool system: true

    signal read(string line)

    running: true
    command: ["gdbus", "monitor", system ? "--system" : "--session", "--dest", dest]
    stdout: SplitParser {
        onRead: data => root.read(data)
    }

    property real startedAt: 0
    onRunningChanged: if (running) startedAt = Date.now()
    onExited: {
        retry.interval = Date.now() - startedAt > 10000 ? 5000 : Math.min(retry.interval * 2, 300000);
        retry.start();
    }

    readonly property Timer retry: Timer {
        interval: 5000
        onTriggered: root.running = true
    }
}
