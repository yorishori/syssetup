pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.I3
import Quickshell.Wayland
import qs.core

// Window manager state and actions. The only file that talks to the
// compositor, with a Sway and a Hyprland backend picked at startup from the
// environment. Windows come from the foreign-toplevel protocol, which both
// support.
Singleton {
    id: root

    readonly property bool sway: !!Quickshell.env("SWAYSOCK")
    readonly property bool hyprland: !sway && !!Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
    readonly property bool available: sway || hyprland

    readonly property int activeWorkspace: sway ? I3.focusedWorkspace?.number ?? 0
        : hyprland ? Hyprland.focusedWorkspace?.id ?? 0 : 0

    // Regular workspaces only, as [{ id, occupied }]. Hyprland's special
    // workspaces have negative ids; Sway's scratchpad and named-only
    // workspaces have no number.
    readonly property var workspaces: sway
        ? I3.workspaces.values.filter(w => w.number > 0).map(w => ({
            id: w.number,
            // Sway removes a workspace once it's empty and unfocused, so only
            // the focused one can exist without windows.
            occupied: !w.focused || !!w.lastIpcObject?.representation
        }))
        : hyprland
        ? Hyprland.workspaces.values.filter(w => w.id > 0).map(w => ({
            id: w.id,
            occupied: w.toplevels.values.length > 0
        }))
        : []

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
        if (sway)
            I3.dispatch(`workspace number ${id}`);
        else if (hyprland)
            Hyprland.dispatch(Hyprland.usingLua ? `hl.dsp.focus({ workspace = ${id} })` : `workspace ${id}`);
    }

    // Display power, all monitors.
    function dpms(on: bool): void {
        const action = on ? "on" : "off";
        if (sway)
            I3.dispatch(`output * power ${action}`);
        else if (hyprland)
            Hyprland.dispatch(Hyprland.usingLua ? `hl.dsp.dpms({ action = "${action}" })` : `dpms ${action}`);
    }

    // Sway sends no workspace event when windows come and go, so refresh the
    // workspaces (and with them `occupied`) on window events.
    Loader {
        active: root.sway

        sourceComponent: I3IpcListener {
            subscriptions: ["window"]
            onIpcEvent: I3.refreshWorkspaces()
        }
    }

    HealthCheck {
        source: "wm"
        ok: root.available
        reason: "neither SWAYSOCK nor HYPRLAND_INSTANCE_SIGNATURE is set, not running under Sway or Hyprland"
        grace: 0
    }
}
