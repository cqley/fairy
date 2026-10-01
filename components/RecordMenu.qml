import QtQuick
import Quickshell

Fade {
    id: root
    property int sel: 0
    property bool fast: false
    property bool snap: false
    property int start: 0
    property real px: -1
    property real py: -1
    Timer {
        id: snapRelease
        interval: 0
        onTriggered: root.snap = false
    }
    readonly property var items: Record.items
    readonly property int n: items.length

    width: Theme.recordW - 2 * Theme.recordPad
    height: col.height
    focus: shown

    function move(d, wrap) {
        if (!n)
            return
        const t = wrap ? (sel + d + n) % n : Math.max(0, Math.min(n - 1, sel + d))
        snap = Math.abs(t - sel) > Theme.recordRows
        sel = t
        if (snap)
            snapRelease.restart()
    }

    function reset() {
        snap = true
        sel = 0
        start = 0
        snapRelease.restart()
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
        const w = !e.isAutoRepeat
        root.fast = e.isAutoRepeat
        if (k === Qt.Key_Escape)
            Record.open = false
        else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space)
            root.run()
        else if (k === Qt.Key_Down || k === Qt.Key_J || k === Qt.Key_Tab)
            root.move(1, w)
        else if (k === Qt.Key_Up || k === Qt.Key_K || k === Qt.Key_Backtab)
            root.move(-1, w)
        else if (k === Qt.Key_PageDown)
            root.move(Theme.recordRows, false)
        else if (k === Qt.Key_PageUp)
            root.move(-Theme.recordRows, false)
        else
            return
        e.accepted = true
    }

    Keys.onReleased: e => {
        if (!e.isAutoRepeat)
            root.fast = false
    }

    Column {
        id: col
        width: parent.width
        spacing: 6

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Record.active ? "recording " + Record.clock : "record"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Record.active ? Theme.red : Theme.fg
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.fg
            opacity: 0.1
            visible: root.n > 0
        }

        Item {
            width: parent.width
            height: list.height
            visible: root.n > 0

            ListView {
                id: list
                width: parent.width
                height: Math.min(root.n, Theme.recordRows) * Theme.recordRowH
                clip: true
                interactive: false
                model: root.items
                cacheBuffer: Theme.recordRowH * Theme.recordRows * 2
                reuseItems: true
                contentY: root.start * Theme.recordRowH
                highlightFollowsCurrentItem: false

                Behavior on contentY {
                    enabled: !root.snap
                    NumberAnimation {
                        duration: root.fast ? 60 : Theme.glide
                        easing.type: Theme.ease
                    }
                }

                highlight: Rectangle {
                    y: root.sel * Theme.recordRowH
                    width: list.width
                    height: Theme.recordRowH
                    radius: height / 2
                    color: Theme.chip
                    antialiasing: true

                    Behavior on y {
                        enabled: !root.snap
                        NumberAnimation {
                            duration: root.fast ? 60 : Theme.glide
                            easing.type: Theme.ease
                        }
                    }

                    Rectangle {
                        x: 5
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: 16
                        radius: 1.5
                        color: {
                            const it = root.items[root.sel]
                            return it && it.kind === "stop" ? Theme.red : Theme.accent
                        }
                    }
                }

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool isStop: modelData && modelData.kind === "stop"

                    width: list.width
                    height: Theme.recordRowH

                    Txt {
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            if (!row.modelData)
                                return ""
                            if (row.modelData.kind === "monitor")
                                return row.modelData.label
                            if (row.modelData.kind === "portal")
                                return "portal"
                            return row.modelData.label
                        }
                        elide: Text.ElideRight
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: row.isStop ? Theme.red : Theme.fg
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
                            root.sel = row.index
                        }
                        onClicked: {
                            root.sel = row.index
                            root.run()
                        }
                    }
                }
            }
        }
    }

    Wheel {
        anchors.fill: parent
        onStep: n => root.move(n, false)
    }
}

