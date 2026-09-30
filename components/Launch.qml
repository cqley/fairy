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
    readonly property var raw: find(input.text)
    property var results: raw

    width: Theme.launchW - 2 * Theme.lpad
    height: col.height

    function fuzzy(n, s) {
        let j = 0
        for (let i = 0; i < n.length && j < s.length; i++) if (n[i] === s[j]) j++
        return j === s.length
    }

    function find(q) {
        const s = q.trim().toLowerCase()
        const c = a => Launcher.counts[a.id] || 0
        const byName = (a, b) => a.name.localeCompare(b.name)
        const apps = DesktopEntries.applications.values.filter(a => !a.noDisplay)
        if (!s) {
            const top = apps.filter(a => c(a) > 0).sort((a, b) => c(b) - c(a) || byName(a, b)).slice(0, Theme.rows)
            return top.concat(apps.filter(a => !top.includes(a)).sort(byName))
        }
        const hits = []
        for (const a of apps) {
            const n = a.name.toLowerCase()
            const i = n.indexOf(s)
            const k = i === 0 ? 0 : n.includes(" " + s) ? 1 : i > 0 ? 2 : (a.genericName + " " + a.keywords.join(" ")).toLowerCase().includes(s) ? 3 : fuzzy(n, s) ? 4 : -1
            if (k >= 0) hits.push({ a, k })
        }
        return hits.sort((x, y) => x.k - y.k || c(y.a) - c(x.a) || x.a.name.length - y.a.name.length || byName(x.a, y.a)).slice(0, Theme.rows).map(h => h.a)
    }

    function src(icon) {
        return icon.startsWith("/") ? "file://" + icon : Quickshell.iconPath(icon, true)
    }

    function move(d, wrap) {
        const n = results.length
        if (!n) return
        const t = wrap ? (sel + d + n) % n : Math.max(0, Math.min(n - 1, sel + d))
        snap = Math.abs(t - sel) > Theme.rows
        sel = t
        snap = false
    }

    function clear() {
        snap = true
        input.text = ""
        snap = false
    }

    function run() {
        const a = results[sel]
        if (!a) return
        Launcher.bump(a.id)
        if (a.runInTerminal && a.command) Quickshell.execDetached({ command: Theme.terminal.concat(Array.from(a.command)), workingDirectory: a.workingDirectory })
        else a.execute()
        Launcher.open = false
    }

    onRawChanged: {
        sel = 0
        const r = results || []
        if (raw.length !== r.length || raw.some((a, i) => a !== r[i])) results = raw
    }
    onSelChanged: {
        if (sel < start) start = sel
        else if (sel > start + Theme.rows - 1) start = sel - Theme.rows + 1
    }
    onVisibleChanged: {
        if (visible) input.forceActiveFocus()
        else clear()
    }

    Connections {
        target: Launcher
        function onOpenChanged() {
            if (!Launcher.open) return
            clear()
            input.forceActiveFocus()
        }
    }

    Column {
        id: col
        width: parent.width
        spacing: 6

        Item {
            width: parent.width
            height: Theme.searchH

            Item {
                x: 17
                width: 14
                height: 14
                anchors.verticalCenter: parent.verticalCenter
                opacity: 0.6

                Rectangle {
                    width: 11
                    height: 11
                    radius: 5.5
                    color: "transparent"
                    border.width: 1.5
                    border.color: Theme.fg
                    antialiasing: true
                }

                Rectangle {
                    x: 9.4
                    y: 8.65
                    width: 5
                    height: 1.5
                    radius: 0.75
                    rotation: 45
                    transformOrigin: Item.Left
                    color: Theme.fg
                    antialiasing: true
                }
            }

            TextInput {
                id: input
                x: 48
                width: parent.width - 48 - 12
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.fg
                selectionColor: Theme.accent
                selectedTextColor: Theme.bg
                selectByMouse: true
                font.family: Theme.font
                font.pixelSize: 13
                font.weight: Font.Medium
                clip: true

                Keys.onPressed: e => {
                    const k = e.key
                    const c = e.modifiers & Qt.ControlModifier
                    const w = !e.isAutoRepeat
                    root.fast = e.isAutoRepeat
                    if (k === Qt.Key_Escape) Launcher.open = false
                    else if (k === Qt.Key_Return || k === Qt.Key_Enter) root.run()
                    else if (k === Qt.Key_Down || k === Qt.Key_Tab || c && (k === Qt.Key_J || k === Qt.Key_N)) root.move(1, w)
                    else if (k === Qt.Key_Up || k === Qt.Key_Backtab || c && (k === Qt.Key_K || k === Qt.Key_P)) root.move(-1, w)
                    else if (k === Qt.Key_PageDown) root.move(Theme.rows, false)
                    else if (k === Qt.Key_PageUp) root.move(-Theme.rows, false)
                    else return
                    e.accepted = true
                }

                Keys.onReleased: e => {
                    if (!e.isAutoRepeat) root.fast = false
                }
            }

            Txt {
                x: input.x
                anchors.verticalCenter: parent.verticalCenter
                text: "search"
                visible: input.text === ""
                opacity: 0.4
                font.pixelSize: 13
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.fg
            opacity: 0.1
            visible: root.results.length > 0
        }

        Item {
            id: pane
            width: parent.width
            height: list.height
            visible: root.results.length > 0

            ListView {
                id: list
                width: parent.width
                height: Math.min(root.results.length, Theme.rows) * Theme.rowH
                clip: true
                interactive: false
                model: root.results
                cacheBuffer: Theme.rowH * Theme.rows * 2
                reuseItems: true
                contentY: root.start * Theme.rowH
                highlightFollowsCurrentItem: false

                Behavior on contentY {
                    enabled: !root.snap
                    NumberAnimation { duration: root.fast ? 60 : Theme.glide; easing.type: Theme.ease }
                }

                highlight: Rectangle {
                    y: root.sel * Theme.rowH
                    width: list.width
                    height: Theme.rowH
                    radius: height / 2
                    color: Theme.chip
                    antialiasing: true

                    Behavior on y {
                        enabled: !root.snap
                        NumberAnimation { duration: root.fast ? 60 : Theme.glide; easing.type: Theme.ease }
                    }

                    Rectangle {
                        x: 5
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: 18
                        radius: 1.5
                        color: Theme.accent
                    }
                }

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index

                    width: list.width
                    height: Theme.rowH

                    Rectangle {
                        id: tile
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        radius: 8
                        color: img.status === Image.Error || img.status === Image.Null ? Theme.tile : "transparent"

                        Image {
                            id: img
                            anchors.fill: parent
                            source: root.src(row.modelData.icon)
                            asynchronous: true
                            fillMode: Image.PreserveAspectFit
                            sourceSize: Qt.size(56, 56)
                            visible: status === Image.Ready
                        }

                        Txt {
                            anchors.centerIn: parent
                            text: (row.modelData.name || "?")[0].toLowerCase()
                            visible: img.status === Image.Error || img.status === Image.Null
                            font.weight: Font.Bold
                        }
                    }

                    Column {
                        anchors.left: tile.right
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Txt {
                            width: parent.width
                            text: row.modelData.name
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            font.weight: Font.DemiBold
                        }

                        Txt {
                            width: parent.width
                            text: row.modelData.comment || row.modelData.genericName
                            visible: text !== ""
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            opacity: 0.6
                            font.pixelSize: 10
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onPositionChanged: m => {
                            const p = mapToItem(null, m.x, m.y)
                            if (p.x === root.px && p.y === root.py) return
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

