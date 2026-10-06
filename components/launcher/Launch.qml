import "../core"
import QtQuick
import Quickshell

Pick {
    id: root
    readonly property var raw: find(input.text)
    property var results: raw

    n: results.length
    rows: Theme.rows
    width: Theme.launchW - 2 * Theme.lpad
    height: col.height

    function fuzzy(n, s) {
        let j = 0
        for (let i = 0; i < n.length && j < s.length; i++) if (n[i] === s[j]) j++
        return j === s.length
    }

    function find(q) {
        const s = String(q || "").trim().toLowerCase()
        const c = a => Number(Launcher.counts[a.id]) || 0
        const byName = (a, b) => String(a.name || "").localeCompare(String(b.name || ""))
        const apps = DesktopEntries.applications.values.filter(a => !a.noDisplay)
        if (!s) {
            const top = apps.filter(a => c(a) > 0).sort((a, b) => c(b) - c(a) || byName(a, b)).slice(0, Theme.rows)
            return top.concat(apps.filter(a => !top.includes(a)).sort(byName))
        }
        const hits = []
        for (const a of apps) {
            const n = String(a.name || "").toLowerCase()
            const i = n.indexOf(s)
            const generic = String(a.genericName || "")
            const keywords = Array.from(a.keywords || [])
            const k = i === 0 ? 0 : n.includes(" " + s) ? 1 : i > 0 ? 2 : (generic + " " + keywords.join(" ")).toLowerCase().includes(s) ? 3 : fuzzy(n, s) ? 4 : -1
            if (k >= 0) hits.push({ a, k })
        }
        return hits.sort((x, y) => x.k - y.k || c(y.a) - c(x.a) || String(x.a.name || "").length - String(y.a.name || "").length || byName(x.a, y.a)).slice(0, Theme.rows).map(h => h.a)
    }

    function src(icon) {
        const value = String(icon || "")
        if (value === "")
            return ""
        return value.startsWith("/") || value.indexOf("://") >= 0 ? Theme.url(value) : Quickshell.iconPath(value, true)
    }

    function clear() {
        hold()
        input.text = ""
    }

    function run() {
        const a = results[sel]
        if (!a) return
        Launcher.bump(a.id)
        if (a.runInTerminal && a.command && a.command.length) Quickshell.execDetached({ command: Theme.terminal.concat(Array.from(a.command)), workingDirectory: a.workingDirectory || "" })
        else a.execute()
        Launcher.open = false
    }

    onRawChanged: {
        sel = 0
        const r = results || []
        if (raw.length !== r.length || raw.some((a, i) => a !== r[i])) results = raw
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
        spacing: Theme.listGap

        Item {
            width: parent.width
            height: Theme.searchH

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Theme.chip
                opacity: input.activeFocus ? Theme.launchSearchFocusOpacity : Theme.launchSearchOpacity
                antialiasing: true

                Behavior on opacity { NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease } }
            }

            Item {
                x: Theme.launchSearchIconX
                width: Theme.launchSearchIconBox
                height: Theme.launchSearchIconBox
                anchors.verticalCenter: parent.verticalCenter
                opacity: Theme.launchSearchIconOpacity

                Rectangle {
                    x: Theme.launchSearchLensInset
                    y: Theme.launchSearchLensInset
                    width: Theme.launchSearchLensSize
                    height: Theme.launchSearchLensSize
                    radius: width / 2
                    color: "transparent"
                    border.width: Theme.launchSearchIconBorder
                    border.color: Theme.fg
                    antialiasing: true
                }

                Rectangle {
                    x: Theme.launchSearchHandleX
                    y: Theme.launchSearchHandleY
                    width: Theme.launchSearchHandleW
                    height: Theme.launchSearchHandleH
                    radius: height / 2
                    rotation: 45
                    transformOrigin: Item.Left
                    color: Theme.fg
                    antialiasing: true
                }
            }

            TextInput {
                id: input
                x: Theme.launchSearchTextX
                width: parent.width - Theme.launchSearchTextX - Theme.launchSearchTextRight
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.fg
                selectionColor: Theme.accent
                selectedTextColor: Theme.bg
                selectByMouse: true
                font.family: Theme.font
                font.pixelSize: Theme.fsL
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
                font.pixelSize: Theme.fsL
            }
        }

        Rule { visible: root.n > 0 }

        Item {
            id: pane
            width: parent.width
            height: list.height
            visible: root.n > 0

            ListView {
                id: list
                width: parent.width
                height: Math.min(root.n, Theme.rows) * Theme.rowH
                clip: true
                interactive: false
                model: root.results
                cacheBuffer: Theme.rowH * Theme.rows * 2
                reuseItems: true
                contentY: root.start * Theme.rowH
                highlightFollowsCurrentItem: false

                Behavior on contentY {
                    enabled: !root.snap
                    NumberAnimation { duration: root.dur; easing.type: Theme.ease }
                }

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index

                    width: list.width
                    height: Theme.rowH

                    Rectangle {
                        id: tile
                        x: Theme.launchIconX
                        anchors.verticalCenter: parent.verticalCenter
                        width: Theme.launchIconBox
                        height: Theme.launchIconBox
                        radius: Theme.launchIconRadius
                        color: selected ? Theme.launchIconSelectedFill : Theme.launchIconFill
                        border.color: selected ? Theme.accent : area.containsMouse ? Theme.launchIconHoverBorder : Theme.launchIconBorder
                        border.width: Theme.launchIconBorderWidth
                        antialiasing: true
                        transformOrigin: Item.Center
                        scale: area.pressed ? Theme.feedbackPressScale : selected ? Theme.launchIconSelectedScale : area.containsMouse ? Theme.feedbackHoverScale : 1

                        readonly property bool selected: root.sel === row.index

                        Behavior on scale { NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease } }
                        Behavior on color { ColorAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease } }
                        Behavior on border.color { ColorAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease } }

                        Image {
                            id: img
                            anchors.centerIn: parent
                            width: Theme.launchIconSize
                            height: Theme.launchIconSize
                            source: root.src(row.modelData.icon)
                            asynchronous: true
                            fillMode: Image.PreserveAspectFit
                            sourceSize: Qt.size(Theme.launchIconSourceSize, Theme.launchIconSourceSize)
                            visible: status === Image.Ready
                        }

                        Txt {
                            anchors.centerIn: parent
                            text: String(row.modelData.name || "?").charAt(0).toLowerCase()
                            visible: img.status === Image.Error || img.status === Image.Null
                            font.pixelSize: Theme.launchFallbackPx
                            font.weight: Font.Bold
                        }
                    }

                    Column {
                        anchors.left: tile.right
                        anchors.leftMargin: Theme.launchTextGap
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.rowR
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
                            font.pixelSize: Theme.fsXS
                        }
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        onPositionChanged: m => root.aim(mapToItem(null, m.x, m.y), row.index)
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
