pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool open: false
    property var counts: ({})

    onOpenChanged: if (open) {
        if (Polkit.open) {
            root.open = false
            return
        }
        Power.open = false
        Wallpaper.open = false
        Record.open = false
        Net.open = false
    }

    function bump(id) {
        const c = Object.assign({}, counts)
        c[id] = (c[id] || 0) + 1
        counts = c
        store.setText(JSON.stringify(c))
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", Quickshell.stateDir])
        try { counts = JSON.parse(store.text()) } catch (e) {}
    }

    FileView {
        id: store
        path: Quickshell.statePath("launcher.json")
        blockLoading: true
        printErrors: false
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.open = !root.open }
    }
}
