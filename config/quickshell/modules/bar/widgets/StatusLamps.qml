import QtQuick
import qs.components
import qs.services

// What the machine is doing on its own: the mic, camera or screen in use
// (shared or recorded), and idling (no input, nothing holding it off).
// Indicators only. The skin may hide it while all are off (`shown`).
Skinned {
    readonly property bool mic: Privacy.micActive
    readonly property bool camera: Privacy.cameraActive
    readonly property bool screen: Privacy.screenActive
    readonly property bool idle: Idle.idle
    readonly property bool privacy: mic || camera || screen

    skin: "StatusLamps"
    visible: view?.shown ?? true
}
