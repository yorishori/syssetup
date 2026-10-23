import QtQuick
import qs.components
import qs.services

// Network: wired links, Wi-Fi power and scan, the visible networks, and for
// one of them its actions: connect (with a passphrase if it's new),
// disconnect, forget. The skin (NetworkMenu) lays it out and keeps which
// network is picked.
Skinned {
    id: root

    property bool open: false

    readonly property var wired: Network.wired  // { name, connected }
    readonly property bool wifiEnabled: Network.wifiEnabled
    readonly property bool scanning: Network.scanning
    // { path, name, secure, known, connected, strength (0-100) }, strongest
    // first.
    readonly property var networks: Network.networks
    readonly property bool busy: Network.busy
    readonly property string pending: Network.pending  // name of the network being joined
    readonly property string error: Network.error

    skin: "NetworkMenu"

    function needsPassphrase(network: var): bool {
        return !!network && network.secure && !network.known;
    }
    function scan(): void {
        Network.scan();
    }
    function setWifiEnabled(on: bool): void {
        Network.setWifiEnabled(on);
    }
    function connect(network: var, passphrase: string): void {
        Network.connect(network, passphrase);
    }
    function disconnect(): void {
        Network.disconnect();
    }
    function forget(network: var): void {
        Network.forget(network);
    }
}
