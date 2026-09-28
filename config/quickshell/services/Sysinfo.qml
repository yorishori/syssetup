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
        command: ["sh", "-c", `
            . /etc/os-release 2>/dev/null; echo "os $PRETTY_NAME"
            echo "kernel $(uname -r)"
            [ -d "/usr/lib/modules/$(uname -r)" ] || echo "reboot"
            echo "cpu $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/ with .*//')"
            if command -v nvidia-smi >/dev/null; then
                echo "gpu $(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)"
            else
                echo "gpu $(lspci -mm 2>/dev/null | grep -m1 -E '"(VGA|3D|Display)' | awk -F'"' '{print $6}')"
            fi
            echo "board $(cut -d' ' -f1 /sys/class/dmi/id/board_vendor 2>/dev/null) $(cat /sys/class/dmi/id/board_name 2>/dev/null)"`]
        stdout: StdioCollector {
            onStreamFinished: {
                root.rebootPending = false;
                for (const line of text.split("\n")) {
                    const space = line.indexOf(" ");
                    const key = space < 0 ? line : line.slice(0, space);
                    const value = space < 0 ? "" : line.slice(space + 1).trim();
                    if (key === "reboot")
                        root.rebootPending = true;
                    else if (key in root)
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

        command: ["sh", "-c", `
            head -1 /proc/stat
            grep -E '^(MemTotal|MemAvailable):' /proc/meminfo | tr -s ' ' | cut -d' ' -f1,2
            for h in /sys/class/hwmon/hwmon*; do
                case "$(cat $h/name)" in k10temp|coretemp|zenpower) echo "cputemp $(cat $h/temp1_input)"; break;; esac
            done
            if command -v nvidia-smi >/dev/null; then
                echo "nvidia $(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits | head -1)"
            else
                for c in /sys/class/drm/card*/device/gpu_busy_percent; do [ -r "$c" ] && echo "amdgpu $(cat $c)" && break; done
            fi`]
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
