import QtQuick

QtObject {
    id: root
    property int count: 0
    property int rows: Theme.rows
    property int current: 0
    property int start: 0
    property bool horizontal: false
    property bool fast: false
    property bool snap: false
    property real px: -1
    property real py: -1
    readonly property int duration: fast ? Theme.fast : Theme.glide
    property Timer release: Timer {
        interval: 0
        onTriggered: root.snap = false
    }

    function hold() {
        snap = true
        release.restart()
    }

    function move(d, wrap, page) {
        if (!count)
            return
        const old = current
        const target = wrap ? (old + d + count) % count : Math.max(0, Math.min(count - 1, old + d))
        snap = !!page || Math.abs(target - old) > rows
        current = target
        if (snap)
            release.restart()
    }

    function reset() {
        hold()
        current = 0
        start = 0
    }

    function aim(p, i) {
        if (p.x === px && p.y === py)
            return
        px = p.x
        py = p.y
        current = i
    }

    function key(e) {
        const k = e.key
        const wrap = !e.isAutoRepeat
        fast = e.isAutoRepeat
        if (k === Qt.Key_Tab)
            move(1, wrap, false)
        else if (k === Qt.Key_Backtab)
            move(-1, wrap, false)
        else if (horizontal && (k === Qt.Key_Right || k === Qt.Key_L || k === Qt.Key_D))
            move(1, wrap, false)
        else if (horizontal && (k === Qt.Key_Left || k === Qt.Key_H || k === Qt.Key_A))
            move(-1, wrap, false)
        else if (!horizontal && (k === Qt.Key_Down || k === Qt.Key_J || k === Qt.Key_S))
            move(1, wrap, false)
        else if (!horizontal && (k === Qt.Key_Up || k === Qt.Key_K || k === Qt.Key_W))
            move(-1, wrap, false)
        else if (!horizontal && k === Qt.Key_PageDown)
            move(rows, false, true)
        else if (!horizontal && k === Qt.Key_PageUp)
            move(-rows, false, true)
        else
            return false
        return true
    }

    onCurrentChanged: {
        if (current < start)
            start = current
        else if (current > start + rows - 1)
            start = current - rows + 1
    }
}
