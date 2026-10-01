pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool open: false
    readonly property bool active: proc.running
    property string backend: ""
    property string bin: ""
    property string lastFile: ""
    property string lastError: ""
    property string targetLabel: ""
    property double startedAt: 0
    property int elapsedSec: 0
    property var items: []
    property var pending: null
    property bool intentional: false
    readonly property string clock: {
        const m = Math.floor(elapsedSec / 60)
        const s = elapsedSec % 60
        return m + ":" + String(s).padStart(2, "0")
    }

    onOpenChanged: if (open) {
        if (Polkit.open) {
            root.open = false
            return
        }
        Launcher.open = false
        Power.open = false
        Wallpaper.open = false
        Net.open = false
        refresh()
    }

    function toggle() {
        open = !open
    }

    function stop() {
        if (!proc.running)
            return
        intentional = true
        pending = null
        proc.signal(2)
        settle.restart()
    }

    function refresh() {
        const list = []
        if (proc.running)
            list.push({ kind: "stop", label: "stop recording", value: "" })
        const screens = Quickshell.screens
        for (let i = 0; i < screens.length; i++) {
            const s = screens[i]
            list.push({ kind: "monitor", label: s.name, value: s.name })
        }
        list.push({ kind: "portal", label: "portal", value: "portal" })
        items = list
    }

    function pick(item) {
        if (!item)
            return
        if (item.kind === "stop") {
            stop()
            open = false
            return
        }
        if (proc.running) {
            pending = item
            intentional = true
            proc.signal(2)
            settle.restart()
            open = false
            return
        }
        start(item)
        open = false
    }

    function start(item) {
        if (Theme.recordBin !== "") {
            bin = Theme.recordBin
            backend = Theme.recordBackend !== "" ? Theme.recordBackend : "custom"
        }
        if (bin === "") {
            lastError = "no recorder found"
            return
        }
        lastError = ""
        intentional = false
        const stamp = Qt.formatDateTime(new Date(), "yyyyMMdd-HHmmss")
        const out = Theme.recordDir + "/rec-" + stamp + ".mp4"
        lastFile = out
        targetLabel = item.label
        startedAt = Date.now()
        elapsedSec = 0
        Quickshell.execDetached(["mkdir", "-p", Theme.recordDir])

        if (backend === "gsr") {
            let src = Theme.screen
            if (item.kind === "monitor")
                src = item.value
            else if (item.kind === "portal")
                src = "portal"
            if (src === "portal")
                proc.exec([bin, "-w", "portal", "-f", String(Theme.recordFps), "-a", "default_output", "-restore-portal-session", "yes", "-o", out])
            else
                proc.exec([bin, "-w", src, "-f", String(Theme.recordFps), "-a", "default_output", "-o", out])
        } else if (backend === "wl") {
            const mon = item.kind === "monitor" ? item.value : Theme.screen
            proc.exec([bin, "-o", mon, "-f", out])
        } else {
            const mon = item.kind === "monitor" ? item.value : Theme.screen
            proc.exec([bin, "-a", "-y", "-f", out, "-o", mon])
        }
    }

    Process {
        id: detect
        command: ["sh", "-lc", "command -v gpu-screen-recorder; command -v wf-recorder; command -v wl-screenrec; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0)
                let b = ""
                let path = ""
                for (let i = 0; i < lines.length; i++) {
                    const l = lines[i]
                    if (l.indexOf("gpu-screen-recorder") >= 0) {
                        b = "gsr"
                        path = l
                        break
                    }
                }
                if (b === "") {
                    for (let i = 0; i < lines.length; i++) {
                        const l = lines[i]
                        if (l.indexOf("wf-recorder") >= 0) {
                            b = "wf"
                            path = l
                            break
                        }
                    }
                }
                if (b === "") {
                    for (let i = 0; i < lines.length; i++) {
                        const l = lines[i]
                        if (l.indexOf("wl-screenrec") >= 0) {
                            b = "wl"
                            path = l
                            break
                        }
                    }
                }
                root.backend = b
                root.bin = path
                if (b === "")
                    root.lastError = "no recorder found"
            }
        }
    }

    Process {
        id: proc
        onExited: (code, status) => {
            settle.stop()
            if (root.pending) {
                const item = root.pending
                root.pending = null
                root.intentional = false
                Qt.callLater(() => root.start(item))
                return
            }
            if (code !== 0 && !root.intentional && root.lastError === "")
                root.lastError = "exited " + code
            root.intentional = false
        }
    }

    Timer {
        id: tick
        interval: 1000
        repeat: true
        running: root.active
        onTriggered: root.elapsedSec = Math.floor((Date.now() - root.startedAt) / 1000)
    }

    Timer {
        id: settle
        interval: 1200
        onTriggered: {
            if (proc.running)
                proc.running = false
        }
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", Theme.recordDir])
        if (Theme.recordBin !== "") {
            root.bin = Theme.recordBin
            root.backend = Theme.recordBackend !== "" ? Theme.recordBackend : "custom"
        } else {
            detect.running = true
        }
    }

    IpcHandler {
        target: "record"
        function toggle(): void { root.toggle() }
        function stop(): void { root.stop() }
        function status(): string {
            if (root.active)
                return "recording " + root.backend + " " + root.clock + " " + root.targetLabel + " " + root.lastFile
            if (root.pending)
                return "switching"
            if (root.lastError !== "")
                return "idle " + root.backend + " " + root.bin + " err:" + root.lastError
            return "idle " + (root.bin !== "" ? root.backend + " " + root.bin : "no-backend")
        }
    }
}
