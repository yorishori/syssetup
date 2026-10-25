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

    // All capture streams are tracked, and only then filtered on their
    // properties (which exist only while tracked). Tracking just the filtered
    // list made a sink-capturing stream (e.g. Steam's game recording) flip in
    // and out of it, binding and unbinding the node until Quickshell crashed.
    readonly property var captureStreams: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioInStream)
    readonly property var micStreams: captureStreams.filter(n => n.properties["stream.capture.sink"] !== "true")
    readonly property bool micActive: micStreams.length > 0
    readonly property var micApps: [...new Set(micStreams.map(n => Audio.nodeName(n)))]

    property bool cameraActive: false
    property bool hasCamera: true

    // Screen: shared through the wlr portal (its Pipewire video streams,
    // xdpw…, exist only while sharing), or being recorded by the shell itself.
    readonly property bool sharing: Pipewire.nodes.values.some(n => /^xdpw/.test(n.name))
    readonly property bool screenActive: sharing || (Capture.recording && Capture.kind === "screen")
    property bool fuserMissing: false

    PwObjectTracker {
        objects: root.captureStreams
    }

    Process {
        id: camera

        // "none" without a camera; else whether one is open, and if fuser is there.
        command: ["sh", "-c", "ls /dev/video* >/dev/null 2>&1 || { echo none; exit; }; fuser /dev/video* >/dev/null 2>&1; echo $?; command -v fuser >/dev/null || echo missing"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                root.hasCamera = lines[0] !== "none";
                root.cameraActive = lines[0] === "0";
                root.fuserMissing = lines.includes("missing");
            }
        }
    }

    // Asked every 2 s while there's a camera; without one, only whether one
    // has been plugged in, every minute.
    Timer {
        interval: root.hasCamera ? 2000 : 60000
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
