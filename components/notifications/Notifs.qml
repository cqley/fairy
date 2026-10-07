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
            armHold(current)
    }

    function dwellFor(n) {
        if (!n || n.system)
            return Theme.dwell
        const t = Number(n.expireTimeout)
        if (isFinite(t) && t === 0)
            return 0
        if (isFinite(t) && t > 0)
            return Math.max(500, Math.round(t * 1000))
        if (n.urgency === NotificationUrgency.Critical)
            return Theme.dwellCritical
        return Theme.dwell
    }

    function armHold(n) {
        const ms = dwellFor(n)
        if (ms <= 0) {
            hold.stop()
            return
        }
        hold.interval = ms
        hold.restart()
    }

    function sameId(a, b) {
        return a && b && !a.system && !b.system && a.id === b.id
    }

    function push(n) {
        if (!n)
            return
        n.tracked = true

        if (sameId(current, n)) {
            current = n
            if (!hovered)
                armHold(n)
            return
        }

        const qi = queue.findIndex(x => sameId(x, n))
        if (qi >= 0) {
            const next = queue.slice()
            next[qi] = n
            queue = next
            return
        }

        queue = [...queue, n].slice(-Theme.notificationQueueMax)
        if (current === null && !gap.running)
            pump()
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
            charging: charging
        }].slice(-Theme.notificationQueueMax)
        if (current === null && !gap.running)
            pump()
    }

    function alive(n) {
        if (!n)
            return false
        if (n.system)
            return true
        return n.tracked !== false
    }

    function pump() {
        const q = queue.filter(alive)
        queue = q.slice(1)
        if (q.length === 0)
            return
        current = q[0]
        if (!hovered)
            armHold(current)
    }

    function next() {
        hold.stop()
        current = null
        gap.restart()
    }

    function dismiss() {
        const n = current
        if (!n)
            return
        next()
        if (!n.system)
            n.dismiss()
    }

    function drop() {
        const n = current
        if (!n)
            return
        next()
        if (!n.system)
            n.expire()
    }

    Timer {
        id: hold
        onTriggered: root.drop()
    }

    Timer {
        id: gap
        interval: Theme.speed
        onTriggered: root.pump()
    }

    Connections {
        id: watched
        property var item: root.current && !root.current.system ? root.current : null
        target: item
        ignoreUnknownSignals: true
        function onClosed() {
            if (root.current === item)
                root.next()
        }
    }

    NotificationServer {
        actionsSupported: true
        bodySupported: true
        imageSupported: true
        keepOnReload: false
        onNotification: n => root.push(n)
    }
}
