import QtQuick
import Quickshell

Fade {
    id: root
    property int sel: 0
    property bool snap: false
    property int start: 0
    property real px: -1
    property real py: -1
    readonly property var items: Record.items
    readonly property int n: items.length

    width: Theme.recordW - 2 * Theme.recordPad
    height: col.height
    focus: shown

    function move(d) {
        if (!n)
            return
        const t = (sel + d + n) % n
        snap = Math.abs(t - sel) > Theme.recordRows
        sel = t
        snap = false
    }

    function reset() {
        snap = true
        sel = 0
        start = 0
        snap = false
    }

    function run() {
        if (!n)
            return
        Record.pick(items[sel])
    }

    onSelChanged: {
        if (sel < start)
            start = sel
        else if (sel > start + Theme.recordRows - 1)
            start = sel - Theme.recordRows + 1
    }

    onVisibleChanged: {
        if (visible)
            forceActiveFocus()
        else
            reset()
    }

    Connections {
        target: Record
        function onOpenChanged() {
            if (!Record.open)
                return
            root.reset()
            root.forceActiveFocus()
        }
        function onItemsChanged() {
            if (root.sel >= root.n)
                root.sel = Math.max(0, root.n - 1)
        }
    }

    Keys.onPressed: e => {
        const k = e.key
        if (k === Qt.Key_Escape)
            Record.open = false
        else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space)
            root.run()
        else if (k === Qt.Key_Down || k === Qt.Key_J || k === Qt.Key_Tab)
            root.move(1)
        else if (k === Qt.Key_Up || k === Qt.Key_K || k === Qt.Key_Backtab)
            root.move(-1)
        else
            return
        e.accepted = true
    }

    Column {
        id: col
        width: parent.width
        spacing: 8

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Record.active ? "recording " + Record.clock : "record"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Record.active ? Theme.red : Theme.fg
        }

        Column {
            width: parent.width
            spacing: 2

            Repeater {
                model: Math.min(Theme.recordRows, Math.max(0, root.n - root.start))

                Rectangle {
                    id: row
                    required property int index
                    readonly property int realIndex: root.start + index
                    readonly property var item: root.items[realIndex]
                    readonly property bool on: root.sel === realIndex
                    readonly property bool isStop: item && item.kind === "stop"

                    width: parent.width
                    height: Theme.recordRowH
                    radius: 10
                    color: on ? Theme.tile : "transparent"
                    antialiasing: true

                    Behavior on color {
                        enabled: !root.snap
                        ColorAnimation { duration: Theme.fade }
                    }

                    Txt {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 24
                        text: {
                            if (!row.item)
                                return ""
                            if (row.item.kind === "monitor")
                                return row.item.label
                            if (row.item.kind === "portal")
                                return "portal"
                            return row.item.label
                        }
                        elide: Text.ElideRight
                        font.pixelSize: 13
                        color: row.isStop ? Theme.red : Theme.fg
                        opacity: row.on ? 1 : 0.7
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: m => {
                            const p = mapToItem(null, m.x, m.y)
                            if (p.x === root.px && p.y === root.py)
                                return
                            root.px = p.x
                            root.py = p.y
                            root.sel = row.realIndex
                        }
                        onClicked: {
                            root.sel = row.realIndex
                            root.run()
                        }
                    }
                }
            }
        }
    }

    Wheel {
        anchors.fill: parent
        onStep: n => root.move(n)
    }
}
