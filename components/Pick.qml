import QtQuick

Fade {
    id: root
    property int n: 0
    property int rows: 5
    property int sel: 0
    property int start: 0
    property bool fast: false
    property bool snap: false
    property real px: -1
    property real py: -1
    readonly property int dur: fast ? Theme.fast : Theme.glide

    Timer {
        id: release
        onTriggered: root.snap = false
    }

    function hold() {
        snap = true
        release.restart()
    }

    function move(d, wrap) {
        if (!n)
            return
        const t = wrap ? (sel + d + n) % n : Math.max(0, Math.min(n - 1, sel + d))
        snap = Math.abs(t - sel) > rows
        sel = t
        if (snap)
            release.restart()
    }

    function reset() {
        hold()
        sel = 0
        start = 0
    }

    function aim(p, i) {
        if (p.x === px && p.y === py)
            return
        px = p.x
        py = p.y
        sel = i
    }

    function nav(e) {
        const k = e.key
        const w = !e.isAutoRepeat
        fast = e.isAutoRepeat
        if (k === Qt.Key_Down || k === Qt.Key_J || k === Qt.Key_Tab)
            move(1, w)
        else if (k === Qt.Key_Up || k === Qt.Key_K || k === Qt.Key_Backtab)
            move(-1, w)
        else if (k === Qt.Key_PageDown)
            move(rows, false)
        else if (k === Qt.Key_PageUp)
            move(-rows, false)
        else
            return false
        return true
    }

    onSelChanged: {
        if (sel < start)
            start = sel
        else if (sel > start + rows - 1)
            start = sel - rows + 1
    }

    Keys.onReleased: e => {
        if (!e.isAutoRepeat)
            fast = false
    }
}
