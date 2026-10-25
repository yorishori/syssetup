import QtQuick
import qs.core

// One bar widget (widgets/<widget>.qml), loaded in isolation: a broken one
// is reported to Health and leaves its slot empty, the rest of the bar keeps
// working. Drops hang from the slot.
Loader {
    required property string widget

    source: Qt.resolvedUrl(`widgets/${widget}.qml`)
    onStatusChanged: {
        if (status === Loader.Error)
            Health.reportBroken(`bar: ${widget}`, source);
    }
}
