pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.core

// Is anything recording? Mic: Pipewire capture streams from an input device
// (streams capturing an output, e.g. visualizers, don't count). Camera: any
// process holding /dev/video* open, checked with fuser every 2s (covers apps
// using V4L2 directly as well as Pipewire's camera).
Singleton {
    id: root

    readonly property var micStreams: Pipewire.nodes.values.filter(n =>
        n.type === PwNodeType.AudioInStream && n.properties["stream.capture.sink"] !== "true")
    readonly property bool micActive: micStreams.length > 0
    readonly property var micApps: [...new Set(micStreams.map(n => Audio.nodeName(n)))]

    property bool cameraActive: false

    // Screen: shared through the wlr or Hyprland portal (their Pipewire video
    // streams, xdpw…/xdph…, exist only while sharing), or being recorded by
    // the shell itself.
    readonly property bool sharing: Pipewire.nodes.values.some(n => /^xd(pw|ph)/.test(n.name))
    readonly property bool screenActive: sharing || (Capture.recording && Capture.kind === "screen")
    property bool fuserMissing: false

    PwObjectTracker {
        objects: root.micStreams
    }

    Process {
        id: camera

        command: ["sh", "-c", "fuser /dev/video* >/dev/null 2>&1; echo $?; command -v fuser >/dev/null || echo missing"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                root.cameraActive = lines[0] === "0";
                root.fuserMissing = lines.includes("missing");
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: camera.running = true
    }

    HealthCheck {
        source: "privacy"
        ok: !root.fuserMissing
        reason: "fuser not found (install psmisc); camera use can't be detected"
        grace: 0
    }

    // qs ipc call privacy status
    IpcHandler {
        target: "privacy"

        function status(): string {
            return `mic: ${root.micActive ? root.micApps.join(", ") : "idle"}\ncamera: ${root.cameraActive ? "in use" : "idle"}\nscreen: ${root.sharing ? "shared" : root.screenActive ? "recording" : "idle"}`;
        }
    }
}
