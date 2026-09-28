import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.core
import qs.services

// Wallpaper: config.json → wallpaper.path on every screen (a second monitor
// gets it too, so it's never a black hole). Changing it crossfades. No image,
// or one that can't be loaded, leaves a plain color: wallpaper.color, or the
// console color when that's empty.
Scope {
    id: root

    // "~/…" and file:// both work.
    readonly property string path: {
        const p = Config.wallpaper.path ?? "";
        return p.startsWith("~/") ? Quickshell.env("HOME") + p.slice(1) : p.replace(/^file:\/\//, "");
    }
    readonly property int fillMode: ({
        fill: Image.PreserveAspectCrop,
        fit: Image.PreserveAspectFit,
        center: Image.Pad,
        tile: Image.Tile
    })[Config.wallpaper.fit] ?? Image.PreserveAspectCrop

    property string failed: ""  // the path that couldn't be loaded

    Variants {
        model: Display.screens

        PanelWindow {
            id: win

            required property ShellScreen modelData

            screen: modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: Config.wallpaper.color || Config.colors.bg
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "qs-wallpaper"

            // The old image stays underneath while the new one fades in.
            Image {
                id: back

                anchors.fill: parent
                fillMode: root.fillMode
                sourceSize: front.sourceSize
                cache: true
            }

            Image {
                id: front

                readonly property string target: root.path ? `file://${root.path}` : ""

                anchors.fill: parent
                fillMode: root.fillMode
                // Decode at screen size (fill / fit); center and tile need it as is.
                sourceSize: root.fillMode === Image.PreserveAspectCrop || root.fillMode === Image.PreserveAspectFit
                    ? Qt.size(win.width, win.height) : undefined
                asynchronous: true
                cache: true
                opacity: 0

                function swap(): void {
                    back.source = status === Image.Ready ? source : "";
                    fade.stop();
                    opacity = 0;
                    source = target;
                    if (!target)
                        root.failed = "";
                }

                onTargetChanged: swap()
                Component.onCompleted: swap()
                onStatusChanged: {
                    if (status === Image.Ready) {
                        fade.restart();
                        root.failed = "";
                    } else if (status === Image.Error) {
                        back.source = "";
                        root.failed = root.path;
                    }
                }

                NumberAnimation on opacity {
                    id: fade

                    running: false
                    to: 1
                    duration: 400
                    easing.type: Easing.OutCubic
                    onFinished: back.source = ""
                }
            }
        }
    }

    HealthCheck {
        source: "wallpaper"
        ok: !root.failed
        reason: `can't load ${root.failed}`
        grace: 0
    }

    // qs ipc call wallpaper <set PATH|get>
    IpcHandler {
        target: "wallpaper"

        function set(path: string): void { Config.set("wallpaper.path", path); }
        function get(): string { return root.path || "none"; }
    }
}
