pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool open: false
    property bool enabled: true
    property string active: ""
    property string error: ""
    property string asking: ""
    property var list: []
    property bool busy: false
    property bool toggling: false

    readonly property string title: {
        if (!enabled)
            return "wifi off"
        if (active !== "")
            return active
        return "network"
    }

    onOpenChanged: if (open) {
        if (Polkit.open) {
            root.open = false
            return
        }
        Launcher.open = false
        Power.open = false
        Wallpaper.open = false
        Record.open = false
        asking = ""
        error = ""
        refresh()
        poll.restart()
    } else {
        poll.stop()
        asking = ""
        error = ""
    }

    function refresh() {
        if (!toggling)
            radio.running = true
        if (enabled)
            scan.running = true
    }

    function toggleWifi() {
        if (toggling)
            return
        const next = enabled ? "off" : "on"
        toggling = true
        enabled = next === "on"
        if (!enabled) {
            list = []
            active = ""
        }
        radioSet.command = ["nmcli", "radio", "wifi", next]
        radioSet.running = true
    }

    function pick(item) {
        if (!item || busy)
            return
        error = ""
        if (item.active) {
            busy = true
            down.command = ["nmcli", "connection", "down", item.ssid]
            down.running = true
            return
        }
        if (asking === item.ssid)
            return
        busy = true
        asking = ""
        up.command = ["nmcli", "device", "wifi", "connect", item.ssid]
        up.running = true
    }

    function submitPsk(psk) {
        if (asking === "" || psk === "" || busy)
            return
        error = ""
        busy = true
        up.command = ["nmcli", "device", "wifi", "connect", asking, "password", psk]
        up.running = true
    }

    function cancelAsk() {
        asking = ""
        error = ""
        busy = false
    }

    function parseWifi(text) {
        const rows = []
        const lines = text.trim().split("\n")
        let cur = ""
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i]
            if (line === "")
                continue
            const p = line.split(":")
            if (p.length < 4)
                continue
            const active = p[0] === "yes"
            const sig = parseInt(p[1]) || 0
            const ssid = p[2]
            const sec = p.slice(3).join(":")
            if (ssid === "" || ssid === "--")
                continue
            if (active)
                cur = ssid
            const locked = sec !== "" && sec !== "--" && sec.toLowerCase().indexOf("open") < 0
            rows.push({
                ssid: ssid,
                signal: Math.max(0, Math.min(100, sig)) / 100,
                active: active,
                locked: locked,
                security: sec
            })
        }
        rows.sort((a, b) => {
            if (a.active !== b.active)
                return a.active ? -1 : 1
            return b.signal - a.signal
        })
        const seen = {}
        const uniq = []
        for (let i = 0; i < rows.length; i++) {
            const r = rows[i]
            if (seen[r.ssid])
                continue
            seen[r.ssid] = true
            uniq.push(r)
        }
        list = uniq
        active = cur
    }

    Process {
        id: radioSet
        onExited: code => {
            root.toggling = false
            radio.running = true
            if (root.enabled)
                scan.running = true
        }
    }

    Process {
        id: radio
        command: ["nmcli", "-t", "-f", "WIFI", "radio"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.toggling)
                    return
                const t = text.trim().toLowerCase()
                root.enabled = t === "enabled"
                if (!root.enabled) {
                    root.list = []
                    root.active = ""
                }
            }
        }
    }

    Process {
        id: scan
        command: ["nmcli", "-t", "-f", "ACTIVE,SIGNAL,SSID,SECURITY", "device", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.parseWifi(text)
        }
    }

    Process {
        id: up
        stdout: StdioCollector {
            onStreamFinished: {}
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const t = text.trim().toLowerCase()
                if (t.indexOf("password") >= 0 || t.indexOf("secrets") >= 0 || t.indexOf("802-11-wireless-security") >= 0) {
                    if (root.asking === "" && up.command.length >= 5)
                        root.asking = up.command[4]
                    root.error = ""
                } else if (t !== "") {
                    root.error = "failed"
                    root.asking = ""
                }
            }
        }
        onExited: code => {
            root.busy = false
            if (code === 0) {
                root.asking = ""
                root.error = ""
            } else if (root.asking === "" && up.command.length >= 5) {
                root.asking = up.command[4]
            }
            root.refresh()
        }
    }

    Process {
        id: down
        onExited: code => {
            root.busy = false
            root.refresh()
        }
    }

    Timer {
        id: poll
        interval: 4000
        repeat: true
        onTriggered: root.refresh()
    }

    IpcHandler {
        target: "network"
        function toggle(): void { root.open = !root.open }
        function status(): string {
            if (!root.enabled)
                return "wifi off"
            if (root.active !== "")
                return "connected " + root.active
            return "idle"
        }
    }
}
