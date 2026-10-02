pragma Singleton
import "../core"
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
    property string pending: ""
    property string phase: ""
    property string target: ""
    property string secret: ""
    property string activeConnection: ""

    readonly property string title: {
        if (!enabled)
            return "wifi off"
        if (phase === "connecting")
            return "connecting…"
        if (phase === "disconnecting")
            return "disconnecting…"
        if (active !== "")
            return active
        return "network"
    }

    onOpenChanged: if (open) {
        Modal.claim("net")
        if (!open)
            return
        asking = ""
        error = ""
        if (!busy) {
            pending = ""
            phase = ""
        }
        refresh()
        poll.restart()
    } else {
        poll.stop()
        if (asking !== "")
            cancelAsk()
        error = ""
        if (!busy) {
            pending = ""
            phase = ""
        }
    }

    function refresh() {
        if (!toggling) {
            radio.running = true
            activeCon.running = true
        }
        if (enabled && !activeCon.running)
            scan.running = true
    }

    function toggleWifi() {
        if (toggling || busy)
            return
        const next = enabled ? "off" : "on"
        toggling = true
        enabled = next === "on"
        if (!enabled) {
            list = []
            active = ""
            activeConnection = ""
            pending = ""
            phase = ""
        }
        radioSet.command = ["nmcli", "radio", "wifi", next]
        radioSet.running = true
    }

    function pick(item) {
        if (!item || busy || toggling)
            return
        error = ""
        if (item.active) {
            busy = true
            pending = item.ssid
            phase = "disconnecting"
            down.command = ["nmcli", "connection", "down", "id", item.connection]
            down.running = true
            return
        }
        if (asking === item.ssid)
            return
        busy = true
        pending = item.ssid
        phase = "connecting"
        asking = ""
        target = item.ssid
        secret = ""
        up.command = ["nmcli", "device", "wifi", "connect", item.ssid]
        up.running = true
    }

    function submitPsk(psk) {
        if (asking === "" || psk === "" || busy)
            return
        error = ""
        busy = true
        pending = asking
        phase = "connecting"
        target = asking
        asking = ""
        secret = psk
        if (up.running) {
            up.write(secret + "\n")
            secret = ""
            return
        }
        up.command = ["nmcli", "--ask", "device", "wifi", "connect", target]
        up.running = true
    }

    function cancelAsk() {
        if (up.running)
            up.signal(15)
        asking = ""
        error = ""
        busy = false
        secret = ""
        target = ""
        pending = ""
        phase = ""
    }

    function readPrompt(text) {
        if (!up.running || root.asking !== "")
            return
        const t = text.toLowerCase()
        if (t.indexOf("password") >= 0 || t.indexOf("passphrase") >= 0 || t.indexOf("secret") >= 0) {
            root.asking = root.target
            root.error = ""
            root.busy = false
            root.phase = ""
        }
    }

    function clearPhase() {
        pending = ""
        phase = ""
    }

    function fields(line) {
        const out = [""]
        for (let i = 0; i < line.length; i++) {
            const c = line[i]
            if (c === "\\" && i + 1 < line.length)
                out[out.length - 1] += line[++i]
            else if (c === ":")
                out.push("")
            else
                out[out.length - 1] += c
        }
        return out
    }

    function parseWifi(text) {
        const rows = []
        const lines = text.trim().split("\n")
        let cur = ""
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i]
            if (line === "")
                continue
            const p = fields(line)
            if (p.length < 4)
                continue
            const active = p[0] === "yes"
            const sig = parseInt(p[1]) || 0
            const ssid = p[2]
            const sec = p[3]
            if (ssid === "" || ssid === "--")
                continue
            if (active)
                cur = ssid
            const locked = sec !== "" && sec !== "--" && sec.toLowerCase().indexOf("open") < 0
            rows.push({
                ssid: ssid,
                signal: Math.max(0, Math.min(100, sig)) / 100,
                active: active,
                connection: active ? root.activeConnection : ssid,
                locked: locked,
                security: sec
            })
        }
        rows.sort((a, b) => {
            if (root.pending !== "") {
                const ap = a.ssid === root.pending
                const bp = b.ssid === root.pending
                if (ap !== bp)
                    return ap ? -1 : 1
            }
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
            activeCon.running = true
            if (root.enabled && !activeCon.running)
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
                    root.activeConnection = ""
                    root.pending = ""
                    root.phase = ""
                }
            }
        }
    }

    Process {
        id: activeCon
        command: ["nmcli", "-t", "-f", "NAME,TYPE,DEVICE", "connection", "show", "--active"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                root.activeConnection = ""
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i] === "")
                        continue
                    const p = root.fields(lines[i])
                    if (p.length < 3 || p[1] !== "802-11-wireless")
                        continue
                    root.activeConnection = p[0]
                    break
                }
                scan.running = true
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
        stdinEnabled: true
        onStarted: {
            if (root.secret === "")
                return
            write(root.secret + "\n")
            root.secret = ""
        }
        stderr: StdioCollector {
            waitForEnd: false
            onTextChanged: root.readPrompt(text)
        }
        onExited: code => {
            root.busy = false
            if (code === 0) {
                root.asking = ""
                root.error = ""
                root.target = ""
                root.secret = ""
                root.phase = ""
                root.refresh()
                settle.restart()
            } else {
                const t = stderr.text.toLowerCase()
                const needsSecret = t.indexOf("password") >= 0 || t.indexOf("passphrase") >= 0 || t.indexOf("secret") >= 0
                if (root.asking === "" && root.error === "") {
                    if (needsSecret)
                        root.asking = root.target
                    else
                        root.error = "failed"
                }
                if (root.asking === "") {
                    root.target = ""
                    root.secret = ""
                    root.phase = ""
                    root.pending = ""
                }
                root.refresh()
            }
        }
    }

    Process {
        id: down
        onExited: code => {
            root.busy = false
            root.phase = ""
            root.pending = ""
            root.refresh()
        }
    }

    Timer {
        id: guard
        interval: 30000
        running: up.running && root.asking !== ""
        onTriggered: {
            if (up.running)
                up.signal(15)
        }
    }

    Timer {
        id: settle
        interval: 600
        onTriggered: {
            if (!root.busy)
                root.clearPhase()
            root.refresh()
        }
    }

    Timer {
        id: poll
        interval: root.busy ? 1500 : 4000
        repeat: true
        onTriggered: root.refresh()
    }

    IpcHandler {
        target: "network"
        function toggle(): void { root.open = !root.open }
        function status(): string {
            if (!root.enabled)
                return "wifi off"
            if (root.phase !== "")
                return root.phase + " " + root.pending
            if (root.active !== "")
                return "connected " + root.active
            return "idle"
        }
    }
}
