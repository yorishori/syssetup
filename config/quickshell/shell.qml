//@ pragma UseQApplication

import Quickshell
import qs.core

// Module imports only let Quickshell discover the files; nothing is compiled
// until ModuleLoader / the bar's PanelLoader loads it, so one broken module or
// panel can't stop the others.
import qs.modules.wallpaper
import qs.modules.bar
import qs.modules.notifications
import qs.modules.clipboard
import qs.modules.osd
import qs.modules.lock
import qs.modules.capture
import qs.modules.compose
import qs.modules.polkit
import qs.modules.launcher
import qs.modules.calendar
import qs.modules.tray
import qs.modules.network
import qs.modules.bluetooth
import qs.modules.audio
import qs.modules.control
import qs.modules.session
import qs.modules.settings

// Entry point. Only lists modules; each one is loaded in isolation.
ShellRoot {
    ModuleLoader { name: "wallpaper"; path: "modules/wallpaper/Wallpaper.qml" }
    ModuleLoader { name: "bar"; path: "modules/bar/Bar.qml" }
    ModuleLoader { name: "notifications"; path: "modules/notifications/Popups.qml" }
    ModuleLoader { name: "clipboard"; path: "modules/clipboard/ClipboardPanel.qml" }
    ModuleLoader { name: "osd"; path: "modules/osd/Osd.qml" }
    // Never unloaded: the lock must hold with no monitor, and it follows
    // monitors by itself.
    ModuleLoader { name: "lock"; path: "modules/lock/Lock.qml"; needsScreen: false }
    ModuleLoader { name: "capture"; path: "modules/capture/CaptureOverlay.qml" }
    ModuleLoader { name: "capture prompt"; path: "modules/capture/CapturePrompt.qml" }
    ModuleLoader { name: "compose"; path: "modules/compose/ComposePanel.qml" }
    ModuleLoader { name: "polkit"; path: "modules/polkit/PolkitPrompt.qml" }
}
