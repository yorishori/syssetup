pragma Singleton

import QtQuick
import Quickshell
import Quickshell.I3
import Quickshell.Wayland
import qs.core

// Window manager state and actions: the only file that talks to Sway (over
// its IPC). Windows come from the foreign-toplevel protocol.
Singleton {
    id: root

    readonly property bool available: !!Quickshell.env("SWAYSOCK")

    readonly property int activeWorkspace: I3.focusedWorkspace?.number ?? 0

    // Numbered workspaces only, as [{ id, occupied }] (the scratchpad and
    // named-only workspaces have no number).
    readonly property var workspaces: I3.workspaces.values.filter(w => w.number > 0).map(w => ({
        id: w.number,
        // Sway removes a workspace once it's empty and unfocused, so only the
        // focused one can exist without windows.
        occupied: !w.focused || !!w.lastIpcObject?.representation
    }))

    // Open windows: { toplevel, appClass, title }. Sway reports XWayland
    // windows' class as their app id.
    readonly property var windows: ToplevelManager.toplevels.values.map(t => ({
        toplevel: t,
        appClass: t.appId,
        title: t.title
    }))

    // The window that last had focus, as { toplevel, appClass }. Kept while a
    // panel holds the keyboard (Sway reports no active window then), so
    // there's still somewhere to paste into; cleared on an empty workspace.
    property var activeWindow: null

    // Whether that window is fullscreen, covering the bar.
    readonly property bool fullscreen: activeWindow?.toplevel?.fullscreen ?? false

    function forgetOnEmptyWorkspace(): void {
        if (!ToplevelManager.activeToplevel && !isOccupied(activeWorkspace))
            activeWindow = null;
    }

    onActiveWorkspaceChanged: Qt.callLater(forgetOnEmptyWorkspace)
    Component.onCompleted: {
        const t = ToplevelManager.activeToplevel;
        if (t)
            activeWindow = { toplevel: t, appClass: t.appId };
    }

    Connections {
        target: ToplevelManager

        function onActiveToplevelChanged(): void {
            const t = ToplevelManager.activeToplevel;
            if (t)
                root.activeWindow = { toplevel: t, appClass: t.appId };
            else
                Qt.callLater(root.forgetOnEmptyWorkspace);
        }
    }

    function focusWindow(win: var): void {
        win?.toplevel?.activate();
    }

    function isOccupied(id: int): bool {
        return workspaces.some(w => w.id === id && w.occupied);
    }

    function focusWorkspace(id: int): void {
        I3.dispatch(`workspace number ${id}`);
    }

    // Display power, all monitors.
    function dpms(on: bool): void {
        I3.dispatch(`output * power ${on ? "on" : "off"}`);
    }

    // Sway sends no workspace event when windows come and go, so refresh the
    // workspaces (and with them `occupied`) on window events.
    I3IpcListener {
        subscriptions: ["window"]
        onIpcEvent: I3.refreshWorkspaces()
    }

    HealthCheck {
        source: "wm"
        ok: root.available
        reason: "SWAYSOCK isn't set: not running under Sway"
        grace: 0
    }
}
