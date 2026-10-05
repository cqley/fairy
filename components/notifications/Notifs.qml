pragma Singleton
import "../core"
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root
    property var current: null
    property var queue: []
    property bool hovered: false

    onHoveredChanged: if (current) {
        if (hovered)
            hold.stop()
        else
            hold.restart()
    }

    function push(n) {
        n.tracked = true
        queue = [...queue, n]
        if (current === null && !gap.running) pump()
    }

    function pushSystem(summary, body, charging) {
        const duplicate = (current && current.system && current.kind === "battery" && current.summary === summary) ||
            queue.some(n => n && n.system && n.kind === "battery" && n.summary === summary)
        if (duplicate)
            return

        queue = [...queue, {
            system: true,
            kind: "battery",
            summary: summary,
            body: body,
            appName: "fairy",
            appIcon: "",
            image: "",
            urgency: NotificationUrgency.Normal,
            expireTimeout: 4,
            charging: charging
        }]
        if (current === null && !gap.running) pump()
    }

    function pump() {
        const q = queue.filter(n => n)
        queue = q.slice(1)
        if (q.length === 0) return
        current = q[0]
        hold.interval = span(current)
        hard.interval = Math.max(hold.interval * 2, Theme.dwellCritical)
        hard.restart()
        if (!hovered) hold.restart()
    }

    function next() {
        hold.stop()
        hard.stop()
        current = null
        gap.restart()
    }

    function dismiss() {
        const n = current
        if (!n) return
        next()
        if (!n.system)
            n.dismiss()
    }

    function drop() {
        const n = current
        if (!n) return
        next()
        if (!n.system)
            n.expire()
    }

    function span(n) {
        const t = Number(n.expireTimeout) * 1000
        if (isFinite(t) && t > 0) return Math.min(Math.max(t, 3000), 15000)
        return n.urgency === NotificationUrgency.Critical ? Theme.dwellCritical : Theme.dwell
    }

    Timer {
        id: hold
        onTriggered: root.drop()
    }

    Timer {
        id: hard
        onTriggered: root.drop()
    }

    Timer {
        id: gap
        interval: Theme.speed
        onTriggered: root.pump()
    }

    Connections {
        target: root.current && !root.current.system ? root.current : null
        ignoreUnknownSignals: true
        function onClosed() { root.next() }
    }

    NotificationServer {
        actionsSupported: true
        bodySupported: true
        imageSupported: true
        keepOnReload: false
        onNotification: n => root.push(n)
    }
}
