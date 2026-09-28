import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.core
import qs.services

// On-screen display: a small drawer rises from the bottom edge for a moment
// when the output volume, output mute or mic mute changes (keys, apps, the
// CLI, anything). Click-through; skipped while the audio panel is open.
PanelWindow {
    id: win

    // What changed last: "volume" or "mic".
    property string kind: "volume"
    property bool shown: false
    property bool armed: false  // ignore the initial values at startup

    readonly property bool micMuted: Audio.input?.audio?.muted ?? false

    function show(what: string): void {
        if (!armed || Panels.isOpen("audio"))
            return;
        kind = what;
        shown = true;
        hideTimer.restart();
    }

    screen: Display.primary
    anchors.bottom: true
    implicitWidth: drawer.width + 2 * drawer.shoulder
    implicitHeight: 80
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: shown || drawer.height > 0
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-osd"

    Connections {
        target: Audio

        function onVolumeChanged(): void { win.show("volume"); }
        function onMutedChanged(): void { win.show("volume"); }
    }
    onMicMutedChanged: show("mic")

    Timer {
        interval: 1500
        running: true
        onTriggered: win.armed = true
    }
    Timer {
        id: hideTimer
        interval: 1400
        onTriggered: win.shown = false
    }

    BottomDrawer {
        id: drawer

        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        width: 380
        open: win.shown

        RowLayout {
            width: parent.width
            spacing: 12

            readonly property bool muted: win.kind === "mic" ? win.micMuted : Audio.muted

            StyledText {
                Layout.preferredWidth: 24
                text: win.kind === "mic"
                    ? (parent.muted ? "\u{F036D}" : "\u{F036C}")
                    : (parent.muted ? "\u{F075F}" : "\u{F057E}")
                color: parent.muted ? Config.colors.off : Config.colors.accent
                glow: !parent.muted
                font.pixelSize: Config.font.size + 5
            }
            Meter {
                Layout.fillWidth: true
                implicitHeight: 10
                interactive: false
                segments: 20
                value: win.kind === "mic" ? (Audio.input?.audio?.volume ?? 0) : Audio.volume
                color: parent.muted ? Config.colors.off : Config.colors.accent
            }
            StyledText {
                Layout.preferredWidth: 44
                horizontalAlignment: Text.AlignRight
                text: parent.muted ? "MUTE" : String(win.kind === "mic" ? Math.round((Audio.input?.audio?.volume ?? 0) * 100) : Audio.percent).padStart(3, "0")
                color: parent.muted ? Config.colors.off : Config.colors.fg
                font.bold: true
                font.letterSpacing: parent.muted ? 1.5 : 0
            }
        }
    }
}
