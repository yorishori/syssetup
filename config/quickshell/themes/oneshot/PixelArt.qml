import QtQuick

// A pixel-art sprite from text: one string per row, one character per
// pixel, looked up in `colors` ("." and anything not in it is clear).
// Each art pixel is `px` screen pixels. `flip` mirrors it.
Canvas {
    id: root

    property var rows: []
    property var colors: ({})
    property int px: 3
    property bool flip: false

    readonly property int columns: rows.reduce((n, r) => Math.max(n, r.length), 0)

    width: columns * px
    height: rows.length * px
    antialiasing: false
    renderStrategy: Canvas.Immediate

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        for (let y = 0; y < rows.length; y++) {
            const row = rows[y];
            for (let x = 0; x < row.length; x++) {
                const color = colors[row[x]];
                if (!color)
                    continue;
                ctx.fillStyle = color;
                ctx.fillRect((flip ? columns - 1 - x : x) * px, y * px, px, px);
            }
        }
    }

    onRowsChanged: requestPaint()
    onColorsChanged: requestPaint()
    onPxChanged: requestPaint()
    onFlipChanged: requestPaint()
}
