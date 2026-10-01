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
    readonly property var items: Net.list
    readonly property int n: items ? items.length : 0
    readonly property bool ask: Net.asking !== ""

    width: Theme.netW - 2 * Theme.netPad
    height: col.height
    focus: shown

    function move(d, wrap) {
        if (!n)
            return
        const t = wrap ? (sel + d + n) % n : Math.max(0, Math.min(n - 1, sel + d))
        snap = Math.abs(t - sel) > Theme.netRows
        sel = t
        snap = false
    }

    function reset() {
        snap = true
        sel = 0
        start = 0
        pass.text = ""
        snap = false
    }

    function run() {
        if (ask) {
            Net.submitPsk(pass.text)
            return
        }
        if (!n)
            return
        Net.pick(items[sel])
    }

    function close() {
        Net.open = false
    }

    onSelChanged: {
        if (sel < start)
            start = sel
        else if (sel > start + Theme.netRows - 1)
            start = sel - Theme.netRows + 1
    }

    onVisibleChanged: {
        if (visible)
            forceActiveFocus()
        else
            reset()
    }

    onAskChanged: {
        if (ask) {
            pass.text = ""
            pass.forceActiveFocus()
        } else if (visible) {
            forceActiveFocus()
        }
    }

    Connections {
        target: Net
        function onOpenChanged() {
            if (!Net.open)
                return
            root.reset()
            root.forceActiveFocus()
        }
        function onListChanged() {
            if (root.sel >= root.n)
                root.sel = Math.max(0, root.n - 1)
        }
    }

    Keys.onPressed: e => {
        const k = e.key
        if (k === Qt.Key_Escape) {
            if (root.ask)
                Net.cancelAsk()
            else
                root.close()
            e.accepted = true
            return
        }
        if (root.ask)
            return
        const w = !e.isAutoRepeat
        root.fast = e.isAutoRepeat
        if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space)
            root.run()
        else if (k === Qt.Key_Down || k === Qt.Key_J || k === Qt.Key_Tab)
            root.move(1, w)
        else if (k === Qt.Key_Up || k === Qt.Key_K || k === Qt.Key_Backtab)
            root.move(-1, w)
        else if (k === Qt.Key_PageDown)
            root.move(Theme.netRows, false)
        else if (k === Qt.Key_PageUp)
            root.move(-Theme.netRows, false)
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

        Item {
            width: parent.width
            height: Theme.netRowH

            Txt {
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: Net.title
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: Net.enabled ? Theme.fg : Theme.red
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                height: 20
                radius: 10
                color: Net.enabled ? Theme.accent : Theme.tile
                antialiasing: true

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.glide
                        easing.type: Theme.ease
                    }
                }

                Rectangle {
                    x: Net.enabled ? parent.width - width - 3 : 3
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14
                    height: 14
                    radius: 7
                    color: Theme.fg
                    antialiasing: true

                    Behavior on x {
                        NumberAnimation {
                            duration: Theme.glide
                            easing.type: Theme.ease
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Net.toggleWifi()
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.fg
            opacity: 0.1
            visible: Net.enabled
        }

        Item {
            width: parent.width
            height: list.height
            visible: Net.enabled && root.n > 0

            ListView {
                id: list
                width: parent.width
                height: Math.min(root.n, Theme.netRows) * Theme.netRowH
                clip: true
                interactive: false
                model: root.items
                cacheBuffer: Theme.netRowH * Theme.netRows * 2
                reuseItems: true
                contentY: root.start * Theme.netRowH
                highlightFollowsCurrentItem: false

                Behavior on contentY {
                    enabled: !root.snap
                    NumberAnimation {
                        duration: root.fast ? 60 : Theme.glide
                        easing.type: Theme.ease
                    }
                }

                highlight: Rectangle {
                    y: root.sel * Theme.netRowH
                    width: list.width
                    height: Theme.netRowH
                    radius: height / 2
                    color: Theme.chip
                    antialiasing: true
                    visible: !root.ask

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
                        color: Theme.accent
                    }
                }

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool on: modelData && modelData.active
                    readonly property real sig: modelData ? modelData.signal : 0
                    readonly property bool locked: modelData && modelData.locked

                    width: list.width
                    height: Theme.netRowH
                    opacity: root.ask && Net.asking !== (modelData ? modelData.ssid : "") ? 0.35 : 1

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.glide
                            easing.type: Theme.ease
                        }
                    }

                    Txt {
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        anchors.right: meta.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData ? row.modelData.ssid : ""
                        elide: Text.ElideRight
                        font.pixelSize: 13
                        font.weight: row.on ? Font.DemiBold : Font.Normal
                        color: row.on ? Theme.accent : Theme.fg
                    }

                    Row {
                        id: meta
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Txt {
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.on ? "connected" : ""
                            font.pixelSize: 11
                            color: Theme.accent
                            opacity: 0.55
                            visible: text !== ""
                        }

                        Item {
                            width: 14
                            height: 12
                            anchors.verticalCenter: parent.verticalCenter
                            visible: row.locked
                            opacity: 0.55

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 0
                                width: 8
                                height: 6
                                radius: 4
                                color: "transparent"
                                border.width: 1.4
                                border.color: Theme.fg
                                antialiasing: true
                            }

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 4
                                width: 10
                                height: 8
                                radius: 2
                                color: Theme.fg
                                antialiasing: true
                            }
                        }

                        Row {
                            id: bars
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            readonly property int level: Math.round(row.sig * 4)

                            Repeater {
                                model: 4
                                Rectangle {
                                    required property int index
                                    anchors.bottom: parent.bottom
                                    width: 3
                                    height: 4 + index * 2
                                    radius: 1
                                    color: Theme.fg
                                    opacity: bars.level > index ? 0.9 : 0.2
                                    antialiasing: true
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.ask
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

        Item {
            width: parent.width
            height: empty.implicitHeight + 8
            visible: Net.enabled && root.n === 0

            Txt {
                id: empty
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                text: "no networks"
                font.pixelSize: 12
                opacity: 0.45
            }
        }

        Column {
            width: parent.width
            spacing: 6
            visible: root.ask

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.fg
                opacity: 0.1
            }

            Txt {
                text: "password for " + Net.asking
                font.pixelSize: 11
                opacity: 0.55
            }

            Rectangle {
                width: parent.width
                height: Theme.netFieldH
                radius: Theme.netFieldH / 2
                color: Theme.chip
                antialiasing: true

                TextInput {
                    id: pass
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.bg
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    selectByMouse: true
                    font.family: Theme.font
                    font.pixelSize: 13
                    clip: true

                    Keys.onPressed: e => {
                        const k = e.key
                        if (k === Qt.Key_Escape) {
                            Net.cancelAsk()
                            root.forceActiveFocus()
                            e.accepted = true
                        } else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
                            root.run()
                            e.accepted = true
                        }
                    }
                }

                Txt {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: "password"
                    opacity: 0.35
                    font.pixelSize: 13
                    visible: pass.text === ""
                }
            }
        }

        Item {
            width: parent.width
            height: err.implicitHeight
            visible: Net.error !== ""

            Txt {
                id: err
                anchors.horizontalCenter: parent.horizontalCenter
                text: Net.error
                color: Theme.red
                font.pixelSize: 11
            }
        }
    }

    Wheel {
        anchors.fill: parent
        enabled: !root.ask
        onStep: n => root.move(n, false)
    }
}
