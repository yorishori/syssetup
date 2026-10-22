import QtQuick

// Looks at an icon: its strongest color (the average of its pixels,
// weighted toward the saturated, opaque ones) and how light it is overall
// (0-1, opaque pixels only). `known` once it's been looked at; until then,
// or if it can't be read, `color` is invalid and `lightness` 0.5.
Canvas {
    id: root

    property string source
    readonly property bool known: found !== null
    readonly property color color: found?.color ?? "transparent"
    readonly property real lightness: found?.lightness ?? 0.5
    property var found: null

    width: 24
    height: 24
    visible: false

    onSourceChanged: {
        found = null;
        if (source)
            loadImage(source);
    }
    onImageLoaded: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        if (!source || !isImageLoaded(source))
            return;
        ctx.clearRect(0, 0, width, height);
        ctx.drawImage(source, 0, 0, width, height);
        const px = ctx.getImageData(0, 0, width, height).data;
        let r = 0, g = 0, b = 0, w = 0, light = 0, solid = 0;
        for (let i = 0; i < px.length; i += 4) {
            const a = px[i + 3] / 255;
            const max = Math.max(px[i], px[i + 1], px[i + 2]), min = Math.min(px[i], px[i + 1], px[i + 2]);
            const weight = a * (0.15 + (max - min) / 255);
            r += px[i] * weight;
            g += px[i + 1] * weight;
            b += px[i + 2] * weight;
            w += weight;
            light += a * (0.299 * px[i] + 0.587 * px[i + 1] + 0.114 * px[i + 2]) / 255;
            solid += a;
        }
        if (w > 0 && solid > 0)
            found = { color: Qt.rgba(r / w / 255, g / w / 255, b / w / 255, 1), lightness: light / solid };
    }
}
