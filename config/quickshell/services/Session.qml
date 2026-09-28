pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import qs.core

// Power actions and the lock, plus hostname and uptime for the session menu.
// Whether the menu is open lives in Panels ("session").
//
// Locking: lock() sets `locked`; the lock module (modules/lock) puts up the
// lock surface and reports `lockSecure` once the compositor confirms. If that
// doesn't happen within 1.5s, Health says so: a lock that silently fails is
// worse than none. Passwords are checked with PAM (/etc/pam.d/login).
//
// logind: any suspend (menu, `systemctl suspend`, the power button) locks
// first, held back by a sleep delay inhibitor until the lock is up;
// `loginctl lock-session` locks too.
Singleton {
    id: root

    property string hostname: ""
    property int uptime: 0  // seconds, refreshed when the menu opens

    readonly property string uptimeText: {
        const d = Math.floor(uptime / 86400), h = Math.floor(uptime % 86400 / 3600), m = Math.floor(uptime % 3600 / 60);
        return d > 0 ? `${d}D ${h}H` : h > 0 ? `${h}H ${m}M` : `${m}M`;
    }

    function poweroff(): void { Quickshell.execDetached(["systemctl", "poweroff"]); }
    function reboot(): void { Quickshell.execDetached(["systemctl", "reboot"]); }

    // Lock first, so the machine wakes up locked.
    function suspend(): void {
        lock();
        suspendDelay.restart();
    }

    // ── Lock ─────────────────────────────────────────────────────────────────

    property bool locked: false
    property bool lockSecure: false  // set by the lock module
    property string authState: ""    // "", "checking", "failed"
    property string authMessage: ""
    property int failures: 0
    property string pending: ""

    function lock(): void {
        Panels.close();
        authState = "";
        authMessage = "";
        locked = true;
        secureCheck.restart();
    }

    function unlockWith(password: string): void {
        if (pam.active || !password)
            return;
        pending = password;
        authState = "checking";
        authMessage = "";
        if (!pam.start()) {
            authState = "failed";
            authMessage = "could not start PAM";
        }
    }

    onLockSecureChanged: {
        if (lockSecure)
            Health.resolve("lock");
    }

    Timer {
        id: secureCheck
        interval: 1500
        onTriggered: {
            if (root.locked && !root.lockSecure)
                Health.report("lock", "the screen did not lock (lock module down?)");
        }
    }

    // ── logind ───────────────────────────────────────────────────────────────

    // Our session's D-Bus path: /org/freedesktop/login1/session/<escaped id>.
    readonly property string sessionPath: {
        const id = Quickshell.env("XDG_SESSION_ID") ?? "";
        const esc = [...id].map((c, i) => /[A-Za-z]/.test(c) || (i > 0 && /[0-9]/.test(c))
            ? c : "_" + c.charCodeAt(0).toString(16).padStart(2, "0")).join("");
        return id ? `/org/freedesktop/login1/session/${esc}` : "";
    }

    Process {
        id: logind

        running: true
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1"]
        stdout: SplitParser {
            onRead: line => {
                if (line.includes(".Manager.PrepareForSleep (true,)")) {
                    root.lock();
                } else if (line.includes(".Session.Lock ()")) {
                    const path = line.split(":")[0];
                    if (!root.sessionPath || path === root.sessionPath)
                        root.lock();
                }
            }
        }
        onExited: logindRetry.start()
    }
    Timer {
        id: logindRetry
        interval: 5000
        onTriggered: logind.running = true
    }

    // Holds sleep back (logind waits up to 5s) until the screen is locked.
    Process {
        id: inhibit

        running: !root.lockSecure
        // cat holds it until the shell closes stdin (stopped, restarted or
        // crashed), so it never outlives the shell.
        stdinEnabled: true
        command: ["systemd-inhibit", "--what=sleep", "--mode=delay", "--who=quickshell",
            "--why=Lock the screen before sleeping", "cat"]
    }

    HealthCheck {
        source: "logind"
        ok: logind.running
        reason: "can't watch logind (gdbus missing?); sleeping won't lock first"
    }

    Timer {
        id: suspendDelay
        interval: 700
        onTriggered: Quickshell.execDetached(["systemctl", "suspend"])
    }

    PamContext {
        id: pam

        // The system's login stack (/etc/pam.d/login), as hyprlock uses.
        config: "login"

        onPamMessage: {
            if (responseRequired) {
                respond(root.pending);
                root.pending = "";
            } else if (messageIsError) {
                root.authMessage = message;
            }
        }
        onCompleted: result => {
            root.pending = "";
            if (result === PamResult.Success) {
                root.authState = "";
                root.failures = 0;
                root.locked = false;
            } else {
                root.authState = "failed";
                root.failures++;
            }
        }
        onError: error => {
            root.pending = "";
            root.authState = "failed";
            root.authMessage = PamError.toString(error);
        }
    }

    function refresh(): void {
        info.running = true;
    }

    Connections {
        target: Panels

        function onCurrentChanged(): void {
            if (Panels.current === "session")
                root.refresh();
        }
    }

    // Prints hostname, then uptime in seconds.
    Process {
        id: info

        running: true
        command: ["sh", "-c", "cat /etc/hostname; cut -d' ' -f1 /proc/uptime"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [host, up] = text.trim().split("\n");
                root.hostname = host ?? "";
                root.uptime = Math.floor(parseFloat(up) || 0);
            }
        }
    }

    // qs ipc call session <lock|toggle|open|close>
    IpcHandler {
        target: "session"

        function lock(): void { root.lock(); }
        function toggle(): void { Panels.toggle("session"); }
        function open(): void { Panels.open("session"); }
        function close(): void {
            if (Panels.isOpen("session"))
                Panels.close();
        }
    }
}
