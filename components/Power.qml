pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool open: false

    onOpenChanged: if (open) {
        if (Polkit.open) {
            root.open = false
            return
        }
        Launcher.open = false
        Wallpaper.open = false
        Record.open = false
    }

    IpcHandler {
        target: "power"
        function toggle(): void { root.open = !root.open }
    }
}
