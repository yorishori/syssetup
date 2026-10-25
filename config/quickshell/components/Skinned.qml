import QtQuick
import qs.core

// Base of every themed widget. The widget is the behaviour: its properties,
// signals, input and timing; it draws nothing itself. Underneath it, the
// active theme's skin (themes/<theme>/<skin>.qml) draws everything, reading
// the widget's state through its `control`:
//
//   // components/Lamp.qml               // themes/cyber/Lamp.qml
//   Skinned {                            Rectangle {
//       skin: "Lamp"                         required property C.Lamp control
//       property bool on                     color: control.on ? … : …
//   }                                    }
//
// The widget takes its size from the skin unless given one; its own children
// sit above the skin. Switching themes swaps the skin live. A skin the theme
// lacks, or has broken, comes from themes/glyphs (see core/Theme.qml); if
// that fails too, `skinFailed` is set and nothing is drawn.
Item {
    id: root

    required property string skin
    // The loaded skin, for widgets that place things by it (TextField's input).
    readonly property Item view: loader.item
    readonly property bool skinFailed: loader.status === Loader.Error

    implicitWidth: loader.item?.implicitWidth ?? 0
    implicitHeight: loader.item?.implicitHeight ?? 0

    Loader {
        id: loader

        readonly property url url: Theme.skinUrl(root.skin)

        function load(): void {
            setSource(url, { control: root });
        }

        anchors.fill: parent
        Component.onCompleted: load()
        onUrlChanged: load()
        onStatusChanged: {
            if (status === Loader.Error)
                Health.report("theme", `${Theme.name}: no ${root.skin} skin could be loaded (see log)`);
        }
    }
}
