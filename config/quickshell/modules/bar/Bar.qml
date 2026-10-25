import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components
import qs.core
import qs.services

// The bar, and the drops that hang from it.
//
// The window is transparent and screen-tall so drops can grow into it, but it
// only reserves the bar's height and only takes input on the bar and the open
// drop. Which panel is open lives in Panels (one at a time); outside click or
// Escape closes it. Each drop's contents is its own module
// (modules/<name>/<Name>Panel.qml), loaded in isolation by PanelLoader, and
// each bar widget too (widgets/<Name>.qml, by BarSlot): a broken one is
// reported and leaves a gap, never takes the bar down.
PanelWindow {
    id: bar

    // The open bar panel, "" when none (or when a panel the bar doesn't
    // show is open).
    readonly property string openDrop: panels.some(p => p.name === Panels.current) ? Panels.current : ""

    // The drops: Panels' bar panels (see Panels.registry), each under the
    // slot of the widget it names, plus the tray's menu, under the app's icon.
    // `bindings` are panel properties kept bound. Themes that show the session
    // menu full screen (SessionScreen) have no drop for it.
    readonly property real tallest: bar.height - Theme.barHeight - 60
    readonly property var panels: [
        ...Panels.registry.filter(p => p.host === "bar").map(p => Object.assign({}, p, {
            under: slotFor(p.under),
            bindings: p.tall ? { maxHeight: () => bar.tallest } : {}
        })),
        { name: "tray", bindings: { item: () => bar.trayItem } }
    ].filter(p => p.name !== "session" || !Theme.sessionScreen)

    // The BarSlot holding `widget`.
    function slotFor(widget: string): Item {
        const find = item => {
            for (const child of item.children) {
                if (child.widget !== undefined) {
                    if (child.widget === widget)
                        return child;
                } else {
                    const found = find(child);
                    if (found)
                        return found;
                }
            }
            return null;
        };
        const slot = find(background);
        if (!slot)
            console.warn(`bar: no slot for widget "${widget}"`);
        return slot;
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
    exclusiveZone: Theme.barHeight
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

    // An open drop takes the keyboard outright, so the launcher can be typed
    // into straight away, and input on the whole screen: a click outside it
    // lands on outsideClick below and closes it.
    WlrLayershell.keyboardFocus: openDrop ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region {
        item: bar.openDrop ? outsideClick : background

        Region { item: bar.activeDrop ?? background }
    }

    // Closes the drop when clicking anywhere outside it. The click doesn't
    // reach the window underneath. Under everything, drops that hang behind
    // the bar included.
    MouseArea {
        id: outsideClick

        z: -2
        anchors.fill: parent
        enabled: bar.openDrop !== ""
        acceptedButtons: Qt.AllButtons
        onPressed: Panels.close()
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Panels.close()
    }

    // Backdrop behind blurring drops: darkens the rest of the screen, and the
    // compositor may blur behind it (SwayFX layer_effects on "qs-bar", see
    // README). Transparent otherwise, so
    // nothing is blurred.
    Backdrop {
        z: -2
        anchors.fill: parent
        shown: bar.panels.some(p => p.blur && p.name === bar.openDrop)
    }

    BarStrip {
        id: background

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: Theme.barHeight
        // The groups of keys, for themes that draw them apart.
        islands: [[leftGroup], [launcher, workspaces, centerRow], [rightGroup]]

        // Left: power, time, tray
        RowLayout {
            id: leftGroup

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: Setup.bar.padding
            }
            spacing: Setup.bar.spacing

            BarSlot { widget: "PowerButton" }
            BarSlot { widget: "Clock" }
            BarSlot { id: tray; widget: "Tray" }
        }

        // Center: launcher key, workspaces, caffeine, status lamps, recording
        BarSlot {
            id: launcher

            widget: "LauncherButton"
            anchors {
                right: workspaces.left
                rightMargin: Setup.bar.spacing
                verticalCenter: parent.verticalCenter
            }
        }
        BarSlot {
            id: workspaces

            widget: "Workspaces"
            anchors.centerIn: parent
        }
        Row {
            id: centerRow

            anchors {
                left: workspaces.right
                leftMargin: Setup.bar.spacing
                verticalCenter: parent.verticalCenter
            }
            spacing: 8

            BarSlot { widget: "CaffeineButton"; anchors.verticalCenter: parent.verticalCenter }
            BarSlot { widget: "StatusLamps"; anchors.verticalCenter: parent.verticalCenter }
            BarSlot { widget: "RecordingKey"; anchors.verticalCenter: parent.verticalCenter }
        }

        // Right: controls
        RowLayout {
            id: rightGroup

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: Setup.bar.padding
            }
            spacing: Setup.bar.spacing

            BarSlot { widget: "NetworkButton" }
            BarSlot { widget: "BluetoothButton" }
            BarSlot { widget: "AudioButton" }
            BarSlot { id: notifications; widget: "NotifIndicator" }
            BarSlot { widget: "HealthIndicator" }
            BarSlot { widget: "ControlButton" }
        }

        // Tell the popups where the notification key is.
        Binding {
            target: Notifs
            property: "slotX"
            value: background.x + rightGroup.x + notifications.x + notifications.width / 2
        }
    }

    // The tray asks for an app's menu; the bar shows it as a drop.
    Connections {
        target: tray.item
        ignoreUnknownSignals: true

        function onMenuRequested(item: var, anchor: Item): void {
            bar.toggleTrayMenu(item, anchor);
        }
    }
    Binding {
        when: tray.item !== null
        target: tray.item
        property: "pulled"
        value: bar.openDrop === "tray" ? bar.trayItem : null
    }

    Repeater {
        id: drops

        model: bar.panels

        Drop {
            id: drop

            required property var modelData

            y: Theme.barHeight - background.seam
            anchorItem: modelData.name === "tray" ? bar.trayAnchor : modelData.under
            name: modelData.name
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
            return tray.item?.openMenu(app) ? "" : `no tray menu matching "${app}"`;
        }
    }
}
