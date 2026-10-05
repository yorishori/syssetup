import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.components
import qs.core
import qs.services
import "widgets"

// The bar, and the drops that hang from it.
//
// The window is transparent and screen-tall so drops can grow into it, but it
// only reserves the bar's height and only takes input on the bar and the open
// drop. Which panel is open lives in Panels (one at a time); outside click or
// Escape closes it. Each drop's contents is its own module
// (modules/<name>/<Name>Panel.qml), loaded in isolation by PanelLoader.
PanelWindow {
    id: bar

    // The open bar panel, "" when none (or when a non-bar panel is open).
    readonly property string openDrop: Panels.barPanels.includes(Panels.current) ? Panels.current : ""

    // Drops, in the order they're declared. `edge` pins one flush to a screen
    // edge; `blur` darkens and blurs the rest of the screen behind it.
    readonly property var panels: [
        { name: "session", edge: "left", blur: true },
        { name: "calendar" },
        { name: "tray", bindings: { item: () => bar.trayItem } },
        { name: "launcher", blur: true },
        { name: "network" },
        { name: "bluetooth" },
        { name: "audio" },
        { name: "notifications" },
        { name: "control", edge: "right", blur: true, bindings: { maxHeight: () => bar.height - Config.bar.height - 60 } },
        { name: "settings", blur: true, bindings: { maxHeight: () => bar.height - Config.bar.height - 60 } },
        { name: "keys", blur: true, bindings: { maxHeight: () => bar.height - Config.bar.height - 60 } }
    ]

    // The bar key each drop hangs under.
    function anchorFor(name: string): Item {
        switch (name) {
        case "session": return powerButton;
        case "calendar": return clock;
        case "tray": return bar.trayAnchor;
        case "launcher": return workspaces;
        case "network": return networkButton;
        case "bluetooth": return bluetoothButton;
        case "audio": return audioButton;
        case "notifications": return notifButton;
        case "control": return controlButton;
        case "settings": return workspaces;
        case "keys": return workspaces;
        }
        return null;
    }

    // The open drop, for the input mask.
    readonly property Item activeDrop: {
        for (let i = 0; i < drops.count; i++) {
            const drop = drops.itemAt(i);
            if (drop?.open)
                return drop;
        }
        return null;
    }

    // Tray menus share one drop; it shows the menu of `trayItem`.
    property var trayItem: null
    property Item trayAnchor: null

    function toggleTrayMenu(item: var, anchor: Item): void {
        if (Panels.isOpen("tray") && trayItem === item) {
            Panels.close();
            return;
        }
        trayItem = item;
        trayAnchor = anchor;
        Panels.open("tray");
    }

    // The app's menu didn't load: show its native menu instead.
    function nativeTrayMenu(): void {
        const pos = trayAnchor.mapToItem(null, 0, trayAnchor.height + 8);
        trayItem.display(bar, pos.x, pos.y);
        Panels.close();
    }

    screen: Display.primary
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: screen?.height ?? 1080
    exclusiveZone: Config.bar.height
    color: "transparent"
    WlrLayershell.namespace: "qs-bar"
    // Fullscreen windows cover the top layer, so an open drop moves up to the
    // overlay: otherwise it would sit hidden behind them, holding the keyboard.
    // A covered surface isn't sent frame callbacks, so Qt stops drawing it and
    // the layer change, applied on the next commit, never lands: remap the
    // bar instead, which comes back on the overlay straight away.
    WlrLayershell.layer: openDrop ? WlrLayer.Overlay : WlrLayer.Top
    visible: !remapping

    property bool remapping: false

    onOpenDropChanged: {
        if (openDrop && Wm.fullscreen && !remapping) {
            remapping = true;
            Qt.callLater(() => remapping = false);
        }
    }

    // An open drop takes the keyboard, so the launcher can be typed into
    // straight away. On Hyprland the focus grab below hands it over, and
    // Exclusive focus would make Hyprland drop the grab, closing the drop.
    // Sway has no grab, so the drop takes the keyboard outright.
    WlrLayershell.keyboardFocus: !openDrop ? WlrKeyboardFocus.None
        : Wm.hyprland ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive

    // Without a focus grab (Sway), an open drop takes input on the whole
    // screen, and a click outside it lands on outsideClick below.
    readonly property bool catchOutside: openDrop !== "" && !Wm.hyprland

    mask: Region {
        item: bar.catchOutside ? outsideClick : background

        Region { item: bar.activeDrop ?? background }
    }

    // Closes the drop when clicking anywhere outside the bar (Hyprland).
    Loader {
        active: Wm.hyprland

        sourceComponent: HyprlandFocusGrab {
            windows: [bar]
            active: bar.openDrop !== ""
            onCleared: {
                if (bar.openDrop)
                    Panels.close();
            }
        }
    }

    // Closes the drop when clicking anywhere outside it (Sway). The click
    // doesn't reach the window underneath.
    MouseArea {
        id: outsideClick

        anchors.fill: parent
        enabled: bar.catchOutside
        acceptedButtons: Qt.AllButtons
        onPressed: Panels.close()
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Panels.close()
    }

    // Backdrop behind blurring drops: darkens the rest of the screen, and the
    // compositor may blur behind it (a Hyprland layer rule or SwayFX
    // layer_effects on "qs-bar", see README). Transparent otherwise, so
    // nothing is blurred.
    Rectangle {
        anchors.fill: parent
        color: Config.colors.bg
        opacity: bar.panels.some(p => p.blur && p.name === bar.openDrop) ? Config.effects.backdrop : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
        }
    }

    Rectangle {
        id: background

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: Config.bar.height
        color: Config.colors.bg  // a dark console strip, distinct from wallpaper and windows

        Scanlines {
            anchors.fill: parent
        }

        // Hairline bottom edge; drops continue it around themselves.
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: Config.shape.border
            color: Config.colors.border
        }

        // Left: power, time, tray
        RowLayout {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: Config.bar.padding
            }
            spacing: Config.bar.spacing

            PowerButton {
                id: powerButton
            }
            Clock {
                id: clock

                active: bar.openDrop === "calendar"
                onClicked: Panels.toggle("calendar")
            }
            Tray {
                id: tray

                onMenuRequested: (trayItem, anchor) => bar.toggleTrayMenu(trayItem, anchor)
            }
        }

        // Center: launcher key, workspaces, recording indicator
        LauncherButton {
            anchors {
                right: workspaces.left
                rightMargin: Config.bar.spacing
                verticalCenter: parent.verticalCenter
            }
            active: bar.openDrop === "launcher"
            onClicked: Panels.toggle("launcher")
        }
        Workspaces {
            id: workspaces

            anchors.centerIn: parent
        }
        Row {
            anchors {
                left: workspaces.right
                leftMargin: Config.bar.spacing
                verticalCenter: parent.verticalCenter
            }
            spacing: 8

            CaffeineButton {
                anchors.verticalCenter: parent.verticalCenter
            }
            // Idling: no input, nothing holding it off.
            BarLabel {
                anchors.verticalCenter: parent.verticalCenter
                text: "\u{F04B2}"
                visible: Idle.idle
            }
            PrivacyIndicator {}
            RecordingKey {}
        }

        // Right: controls
        RowLayout {
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: Config.bar.padding
            }
            spacing: Config.bar.spacing

            NetworkButton {
                id: networkButton
                onToggleDrop: Panels.toggle("network")
            }
            BluetoothButton {
                id: bluetoothButton
                onToggleDrop: Panels.toggle("bluetooth")
            }
            AudioButton {
                id: audioButton
                onToggleDrop: Panels.toggle("audio")
            }
            NotifIndicator {
                id: notifButton

                active: bar.openDrop === "notifications"
                onClicked: Panels.toggle("notifications")
            }
            HealthIndicator {}
            ControlButton {
                id: controlButton

                active: bar.openDrop === "control"
                onClicked: Panels.toggle("control")
            }
        }
    }

    Repeater {
        id: drops

        model: bar.panels

        Drop {
            id: drop

            required property var modelData

            y: Config.bar.height - Config.shape.border
            anchorItem: bar.anchorFor(modelData.name)
            edge: modelData.edge ?? ""
            open: bar.openDrop === modelData.name

            PanelLoader {
                name: drop.modelData.name
                open: drop.open
                bindings: drop.modelData.bindings ?? ({})
                onDone: Panels.close()
                onFallback: bar.nativeTrayMenu()
            }
        }
    }

    // qs ipc call tray menu <app>
    IpcHandler {
        target: "tray"

        function menu(app: string): string {
            return tray.openMenu(app) ? "" : `no tray menu matching "${app}"`;
        }
    }
}
