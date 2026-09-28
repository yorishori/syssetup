import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.core
import qs.services

// Capture overlay: selecting (and, for screenshots, marking) on a frozen
// frame of the primary screen.
//
// Selecting: hover outlines the window under the cursor, click takes it (or
// the whole screen if there's none), drag takes a region, Enter takes the whole
// screen, Escape cancels.
// Marking (screenshots): pen, box, arrow, highlighter, redact block (keys 1-5),
// three inks, Ctrl+Z undo, Enter done, Escape cancel. Only the frame and the
// marks inside the selection are saved.
PanelWindow {
    id: win

    readonly property bool active: Capture.state === "selecting" || Capture.state === "marking"
    readonly property bool marking: Capture.state === "marking"
    readonly property bool ready: frame.item?.hasContent ?? false

    // Selecting
    property rect dragRect: Qt.rect(0, 0, 0, 0)
    property bool dragging: false
    property var hovered: null  // window rect under the cursor

    // Marking
    readonly property var tools: [
        { key: "pen", glyph: "\u{F03EB}" },
        { key: "box", glyph: "\u{F0763}" },
        { key: "arrow", glyph: "\u{F005C}" },
        { key: "mark", glyph: "\u{F0652}" },
        { key: "block", glyph: "\u{F0764}" }
    ]
    readonly property var inks: [Config.colors.warn, Config.colors.error, Config.colors.accent]
    property string tool: "box"
    property color ink: Config.colors.warn
    property var marks: []
    property var current: null

    // What's outlined: the drag, the hovered window, or (marking) the choice.
    readonly property rect shown: marking ? Capture.selection
        : dragging ? dragRect
        : hovered ? Qt.rect(hovered.x, hovered.y, hovered.w, hovered.h)
        : Qt.rect(0, 0, 0, 0)
    readonly property bool hasShown: shown.width > 0 && shown.height > 0

    function windowAt(x: real, y: real): var {
        return Capture.windows.find(w => x >= w.x && x < w.x + w.w && y >= w.y && y < w.y + w.h) ?? null;
    }

    function clamp(v: real, lo: real, hi: real): real {
        return Math.max(lo, Math.min(hi, v));
    }

    function finish(): void {
        const sel = Capture.selection;
        const dpr = win.screen?.devicePixelRatio ?? 1;
        crop.grabToImage(result => {
            const path = `${Capture.tmpDir}/shot-${Date.now()}.png`;
            if (result.saveToFile(path))
                Capture.marked(path);
            else
                Capture.cancel();
        }, Qt.size(Math.round(sel.width * dpr), Math.round(sel.height * dpr)));
    }

    function undo(): void {
        marks = marks.slice(0, -1);
        canvas.requestPaint();
    }

    screen: Display.primary
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: active
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-capture"
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onActiveChanged: {
        dragging = false;
        hovered = null;
        marks = [];
        current = null;
        tool = "box";
        if (active)
            keys.forceActiveFocus();
    }

    // ── The picture: frozen frame + marks (this is what gets saved) ──────────
    Item {
        id: stage

        anchors.fill: parent

        Loader {
            id: frame

            anchors.fill: parent
            active: win.active

            sourceComponent: ScreencopyView {
                captureSource: win.screen
                live: false
                paintCursor: false
            }
        }

        Canvas {
            id: canvas

            anchors.fill: parent

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                for (const m of [...win.marks, ...(win.current ? [win.current] : [])]) {
                    ctx.save();
                    ctx.strokeStyle = m.color;
                    ctx.fillStyle = m.color;
                    ctx.lineJoin = "round";
                    ctx.lineCap = "round";
                    if (m.tool === "pen" || m.tool === "mark") {
                        ctx.lineWidth = m.tool === "mark" ? 18 : 3;
                        ctx.globalAlpha = m.tool === "mark" ? 0.35 : 1;
                        ctx.lineCap = m.tool === "mark" ? "butt" : "round";
                        ctx.beginPath();
                        m.points.forEach((p, i) => i === 0 ? ctx.moveTo(p.x, p.y) : ctx.lineTo(p.x, p.y));
                        ctx.stroke();
                    } else if (m.tool === "box") {
                        ctx.lineWidth = 3;
                        ctx.strokeRect(Math.min(m.x0, m.x1), Math.min(m.y0, m.y1), Math.abs(m.x1 - m.x0), Math.abs(m.y1 - m.y0));
                    } else if (m.tool === "block") {
                        ctx.fillStyle = Config.colors.shadow;
                        ctx.fillRect(Math.min(m.x0, m.x1), Math.min(m.y0, m.y1), Math.abs(m.x1 - m.x0), Math.abs(m.y1 - m.y0));
                    } else if (m.tool === "arrow") {
                        const angle = Math.atan2(m.y1 - m.y0, m.x1 - m.x0);
                        ctx.lineWidth = 3;
                        ctx.beginPath();
                        ctx.moveTo(m.x0, m.y0);
                        ctx.lineTo(m.x1, m.y1);
                        for (const side of [-1, 1]) {
                            ctx.moveTo(m.x1, m.y1);
                            ctx.lineTo(m.x1 - 16 * Math.cos(angle + side * 0.45), m.y1 - 16 * Math.sin(angle + side * 0.45));
                        }
                        ctx.stroke();
                    }
                    ctx.restore();
                }
            }
        }
    }

    // The saved image: the stage, cropped to the selection. Kept behind the
    // stage so it's never seen; grabToImage renders it on demand.
    Item {
        id: crop

        z: -1
        x: Capture.selection.x
        y: Capture.selection.y
        width: Math.max(1, Capture.selection.width)
        height: Math.max(1, Capture.selection.height)
        clip: true

        ShaderEffectSource {
            x: -crop.x
            y: -crop.y
            width: stage.width
            height: stage.height
            sourceItem: stage
        }
    }

    // ── Dimming outside the outlined area ────────────────────────────────────
    Item {
        anchors.fill: parent
        visible: win.ready

        readonly property rect r: win.hasShown ? win.shown : Qt.rect(0, 0, 0, 0)

        Rectangle { x: 0; y: 0; width: parent.width; height: parent.r.y; color: "#000"; opacity: 0.45 }
        Rectangle { x: 0; y: parent.r.y + parent.r.height; width: parent.width; height: parent.height - y; color: "#000"; opacity: 0.45 }
        Rectangle { x: 0; y: parent.r.y; width: parent.r.x; height: parent.r.height; color: "#000"; opacity: 0.45 }
        Rectangle { x: parent.r.x + parent.r.width; y: parent.r.y; width: parent.width - x; height: parent.r.height; color: "#000"; opacity: 0.45 }
    }

    // Outline and size readout
    Rectangle {
        x: win.shown.x - 1
        y: win.shown.y - 1
        width: win.shown.width + 2
        height: win.shown.height + 2
        color: "transparent"
        border.width: 2
        border.color: Config.colors.accent
        visible: win.ready && win.hasShown
    }
    Tag {
        x: win.shown.x
        y: win.shown.y > 28 ? win.shown.y - height - 6 : win.shown.y + 6
        text: `${Math.round(win.shown.width)}×${Math.round(win.shown.height)}`
        fill: Config.colors.accent
        visible: win.ready && win.hasShown && !win.marking
    }

    // How to select, shown the whole time until the shot or recording starts.
    Tag {
        anchors {
            top: parent.top
            topMargin: 48
            horizontalCenter: parent.horizontalCenter
        }
        text: Capture.kind === "screenshot" ? "CLICK A WINDOW · DRAG A REGION · ENTER FOR THE SCREEN" : "RECORD: CLICK A WINDOW · DRAG A REGION · ENTER FOR THE SCREEN"
        fill: Config.colors.surface
        textColor: Config.colors.fg
        size: Config.font.size - 1
        visible: win.ready && !win.marking
    }

    // ── Selecting ────────────────────────────────────────────────────────────
    MouseArea {
        property point from

        anchors.fill: parent
        enabled: Capture.state === "selecting" && win.ready
        hoverEnabled: true
        cursorShape: Qt.CrossCursor

        onPressed: mouse => {
            from = Qt.point(mouse.x, mouse.y);
            win.dragging = false;
        }
        onPositionChanged: mouse => {
            if (pressed && (Math.abs(mouse.x - from.x) > 4 || Math.abs(mouse.y - from.y) > 4))
                win.dragging = true;
            if (win.dragging)
                win.dragRect = Qt.rect(Math.min(from.x, mouse.x), Math.min(from.y, mouse.y), Math.abs(mouse.x - from.x), Math.abs(mouse.y - from.y));
            else
                win.hovered = win.windowAt(mouse.x, mouse.y);
        }
        onReleased: mouse => {
            if (win.dragging && win.dragRect.width > 4 && win.dragRect.height > 4)
                Capture.selected(win.dragRect);
            else {
                const w = win.windowAt(mouse.x, mouse.y);
                Capture.selected(w ? Qt.rect(w.x, w.y, w.w, w.h) : Qt.rect(0, 0, win.width, win.height));
            }
            win.dragging = false;
        }
    }

    // ── Marking ──────────────────────────────────────────────────────────────
    MouseArea {
        x: Capture.selection.x
        y: Capture.selection.y
        width: Capture.selection.width
        height: Capture.selection.height
        enabled: win.marking
        cursorShape: Qt.CrossCursor

        function point(mouse): var {
            return {
                x: win.clamp(mouse.x + x, Capture.selection.x, Capture.selection.x + Capture.selection.width),
                y: win.clamp(mouse.y + y, Capture.selection.y, Capture.selection.y + Capture.selection.height)
            };
        }

        onPressed: mouse => {
            const p = point(mouse);
            win.current = { tool: win.tool, color: win.ink.toString(), points: [p], x0: p.x, y0: p.y, x1: p.x, y1: p.y };
        }
        onPositionChanged: mouse => {
            if (!win.current)
                return;
            const p = point(mouse);
            const c = win.current;
            win.current = Object.assign({}, c, { points: [...c.points, p], x1: p.x, y1: p.y });
            canvas.requestPaint();
        }
        onReleased: {
            if (win.current)
                win.marks = [...win.marks, win.current];
            win.current = null;
            canvas.requestPaint();
        }
    }

    // Tool strip: below the selection if there's room, else above, else inside.
    Item {
        id: strip

        readonly property rect sel: Capture.selection

        x: win.clamp(sel.x + sel.width / 2 - width / 2, 12, win.width - width - 12)
        y: sel.y + sel.height + height + 16 < win.height ? sel.y + sel.height + 12
            : sel.y - height - 12 > 0 ? sel.y - height - 12
            : sel.y + sel.height - height - 12
        width: tools.implicitWidth + 24
        height: tools.implicitHeight + 16
        visible: win.marking

        Card {
            anchors.fill: parent
        }

        RowLayout {
            id: tools

            anchors.centerIn: parent
            spacing: 4

            Repeater {
                model: win.tools

                IconButton {
                    required property var modelData
                    required property int index

                    icon: modelData.glyph
                    lit: win.tool === modelData.key
                    onClicked: win.tool = modelData.key
                }
            }
            Rectangle {
                implicitWidth: 1
                implicitHeight: 20
                color: Config.colors.border
            }
            Repeater {
                model: win.inks

                Item {
                    required property color modelData

                    implicitWidth: 22
                    implicitHeight: 22

                    Chamfer {
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        cut: 4
                        fill: parent.modelData
                        stroke: Qt.colorEqual(win.ink, parent.modelData) ? Config.colors.fg : "transparent"
                        strokeWidth: 2
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.ink = parent.modelData
                    }
                }
            }
            Rectangle {
                implicitWidth: 1
                implicitHeight: 20
                color: Config.colors.border
            }
            IconButton {
                icon: "\u{F054C}"
                enabled: win.marks.length > 0
                opacity: enabled ? 1 : 0.35
                onClicked: win.undo()
            }
            TextButton {
                text: "done"
                lit: true
                onClicked: win.finish()
            }
            TextButton {
                text: "cancel"
                onClicked: Capture.cancel()
            }
        }
    }

    // ── Keys ─────────────────────────────────────────────────────────────────
    Item {
        id: keys

        focus: true

        Keys.onEscapePressed: Capture.cancel()
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (win.marking)
                    win.finish();
                else if (win.ready)
                    Capture.selected(Qt.rect(0, 0, win.width, win.height));
            } else if (win.marking && event.key === Qt.Key_Z && (event.modifiers & Qt.ControlModifier)) {
                win.undo();
            } else if (win.marking && event.key >= Qt.Key_1 && event.key <= Qt.Key_5) {
                win.tool = win.tools[event.key - Qt.Key_1].key;
            }
        }
    }
}
