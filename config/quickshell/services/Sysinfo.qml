pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Hardware and system info. Static facts are read once; live readings (CPU,
// GPU, RAM usage and temperatures) are only sampled while `active` is set,
// e.g. while the control center is open.
Singleton {
    id: root

    property bool active: false

    // Static
    property string os: ""
    property string kernel: ""
    property bool rebootPending: false  // running kernel's modules are gone (kernel updated)
    property string cpu: ""
    property string gpu: ""
    property string board: ""

    // Live, 0..1 for usage; °C for temperatures (-1 = unknown)
    property real cpuUsage: 0
    property int cpuTemp: -1
    property real gpuUsage: 0
    property int gpuTemp: -1
    property real gpuMemUsed: 0   // MiB
    property real gpuMemTotal: 0  // MiB
    property real memUsed: 0      // KiB
    property real memTotal: 0     // KiB

    property var lastCpu: null  // [total, idle] of the previous sample

    function gib(kib: real): string {
        return (kib / 1048576).toFixed(1);
    }

    // ── Static info (once, and again when the panel opens) ───────────────────

    onActiveChanged: {
        if (active) {
            facts.running = true;
            sampler.restart();
        }
    }

    Process {
        id: facts

        running: true
        command: ["sh", Quickshell.shellPath("scripts/sysinfo-facts.sh")]
        stdout: StdioCollector {
            onStreamFinished: {
                root.rebootPending = false;
                for (const line of text.split("\n")) {
                    const space = line.indexOf(" ");
                    const key = space < 0 ? line : line.slice(0, space);
                    const value = space < 0 ? "" : line.slice(space + 1).trim();
                    if (key === "reboot")
                        root.rebootPending = true;
                    else if (["os", "kernel", "cpu", "gpu", "board"].includes(key))
                        root[key] = value;
                }
            }
        }
    }

    // ── Live readings (every 2s while active) ────────────────────────────────

    Timer {
        id: sampler

        interval: 2000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: live.running = true
    }

    Process {
        id: live

        command: ["sh", Quickshell.shellPath("scripts/sysinfo-live.sh")]
        stdout: StdioCollector {
            onStreamFinished: {
                let memAvail = 0;
                for (const line of text.split("\n")) {
                    const f = line.trim().split(/[\s,]+/);
                    if (f[0] === "cpu") {
                        const n = f.slice(1).map(Number);
                        const idle = n[3] + n[4], total = n.reduce((a, b) => a + b, 0);
                        if (root.lastCpu && total > root.lastCpu[0])
                            root.cpuUsage = 1 - (idle - root.lastCpu[1]) / (total - root.lastCpu[0]);
                        root.lastCpu = [total, idle];
                    } else if (f[0] === "MemTotal:") {
                        root.memTotal = Number(f[1]);
                    } else if (f[0] === "MemAvailable:") {
                        memAvail = Number(f[1]);
                    } else if (f[0] === "cputemp") {
                        root.cpuTemp = Math.round(Number(f[1]) / 1000);
                    } else if (f[0] === "nvidia") {
                        root.gpuUsage = Number(f[1]) / 100;
                        root.gpuTemp = Number(f[2]);
                        root.gpuMemUsed = Number(f[3]);
                        root.gpuMemTotal = Number(f[4]);
                    } else if (f[0] === "amdgpu") {
                        root.gpuUsage = Number(f[1]) / 100;
                    }
                }
                root.memUsed = root.memTotal - memAvail;
            }
        }
    }
}
