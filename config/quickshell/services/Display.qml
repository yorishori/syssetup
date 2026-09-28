pragma Singleton

import QtQuick
import Quickshell
import qs.core

// Picks the one screen the shell lives on.
//
// Uses Config.screen when that output is connected, otherwise falls back to the
// first available screen, so plugging or unplugging monitors never breaks it.
// Qt's nameless placeholder (while no monitor is connected) doesn't count.
Singleton {
    readonly property var screens: Quickshell.screens.filter(s => s.name !== "")
    readonly property ShellScreen primary:
        screens.find(s => s.name === Config.screen) ?? screens[0] ?? null
}
