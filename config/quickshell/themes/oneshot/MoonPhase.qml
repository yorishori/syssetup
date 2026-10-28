import QtQuick
import qs.core

// The moon as it is on `date`: a pixel disc, lit on the side the phase
// lights. Also says which phase it is and how much of it shows.
Item {
    id: root

    property date date: new Date()
    property int px: Theme.get("pixel.scale") ?? 3
    property int radius: 8

    // Days into the lunation, from a known new moon (6 Jan 2000, 18:14 UTC).
    readonly property real age: {
        const p = 29.530588853;
        const a = ((date.getTime() - Date.UTC(2000, 0, 6, 18, 14)) / 86400000) % p;
        return a < 0 ? a + p : a;
    }
    readonly property real angle: age / 29.530588853 * 2 * Math.PI
    readonly property real lit: (1 - Math.cos(angle)) / 2
    readonly property string name: {
        const e = age / 29.530588853 * 8;
        return ["New moon", "Waxing crescent", "First quarter", "Waxing gibbous",
                "Full moon", "Waning gibbous", "Last quarter", "Waning crescent"][Math.round(e) % 8];
    }

    implicitWidth: 2 * radius * px
    implicitHeight: 2 * radius * px

    onDateChanged: moon.requestPaint()

    Canvas {
        id: moon

        anchors.fill: parent
        antialiasing: false
        renderStrategy: Canvas.Immediate

        onPaint: {
            const ctx = getContext("2d"), p = root.px, r = root.radius;
            const c = Math.cos(root.angle), waxing = root.angle < Math.PI;
            ctx.clearRect(0, 0, width, height);
            for (let y = 0; y < 2 * r; y++) {
                const dy = y - r + 0.5;
                const w = Math.sqrt(Math.max(0, r * r - dy * dy));
                for (let x = 0; x < 2 * r; x++) {
                    const dx = x - r + 0.5;
                    if (Math.abs(dx) > w)
                        continue;
                    const on = waxing ? dx > w * c : dx < -w * c;
                    ctx.fillStyle = on ? (Math.abs(dx) > w - 1.2 ? "#cbbf9f" : "#e8dcc0") : "#2a2846";
                    ctx.fillRect(x * p, y * p, p, p);
                }
            }
        }
    }
}
