import QtQuick

// Declarative health reporting for services.
//
//     HealthCheck { source: "audio"; ok: Pipewire.ready; reason: "pipewire not reachable" }
//
// A failure is reported once it has lasted `grace` ms, so normal startup delays
// aren't flagged. Recovery is resolved immediately.
QtObject {
    id: root

    required property string source
    property bool ok: true
    property string reason: ""
    property int grace: 3000

    readonly property Timer timer: Timer {
        interval: root.grace
        onTriggered: if (!root.ok) Health.report(root.source, root.reason)
    }

    function update(): void {
        if (ok) {
            timer.stop();
            Health.resolve(source);
        } else if (grace === 0 || source in Health.issues) {
            Health.report(source, reason);
        } else if (!timer.running) {
            timer.start();
        }
    }

    // Deferred, so ok and reason changing together are seen together.
    onOkChanged: Qt.callLater(update)
    onReasonChanged: Qt.callLater(update)
    Component.onCompleted: update()
}
