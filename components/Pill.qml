import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root
    property bool full: false
    readonly property bool hot: hover.hovered
    readonly property bool modal: Modal.any
    readonly property bool alert: Notifs.current !== null && !modal
    readonly property bool calm: !alert && !modal
    property bool media: false
    property real wAnim: Theme.w
    property real hAnim: Theme.h

    onModalChanged: full = false
    onHotChanged: sync()
    Component.onCompleted: sync()

    function sync() {
        media = Media.playing || (hot && media && Media.player !== null)
    }

    Connections {
        target: Media
        function onPlayingChanged() { root.sync() }
        function onPlayerChanged() { root.sync() }
    }

    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    width: body.width
    height: body.height + Theme.gap

    HoverHandler {
        id: hover
        onHoveredChanged: if (!hovered) root.full = false
    }

    TapHandler {
        onTapped: {
            if (root.alert)
                Notifs.dismiss()
            else if (!root.modal && root.hot)
                root.full = !root.full
        }
    }

    Binding {
        target: Notifs
        property: "hovered"
        value: root.hot || root.modal
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property real targetW: Polkit.open ? Theme.authW
        : root.alert ? Theme.noteW
        : Launcher.open ? Theme.launchW
        : Power.open ? Theme.powerW
        : Wallpaper.open ? Theme.wallW
        : Record.open ? Theme.recordW
        : Net.open ? Theme.netW
        : root.hot ? (root.media && !root.full ? Theme.mediaPillW : Theme.openW)
        : Math.max(Theme.w, root.calm ? idle.width + Theme.pad : Theme.w)
    readonly property real targetH: Polkit.open ? auth.y + auth.height + Theme.authPad
        : root.alert ? Theme.noteH
        : Launcher.open ? launch.y + launch.height + Theme.lpad
        : Power.open ? power.y + power.height + Theme.pwPad
        : Wallpaper.open ? wall.y + wall.height + Theme.wallPad
        : Record.open ? rec.y + rec.height + Theme.recordPad
        : Net.open ? net.y + net.height + Theme.netPad
        : root.full ? cal.y + cal.height + Theme.pad
        : root.hot ? (root.media ? tune.y + tune.height + Theme.pad : Theme.openH)
        : Theme.h
    readonly property bool resizing: Math.abs(root.wAnim - root.targetW) > 0.5 || Math.abs(root.hAnim - root.targetH) > 0.5

    Binding {
        target: root
        property: "wAnim"
        value: root.targetW
    }

    Binding {
        target: root
        property: "hAnim"
        value: root.targetH
    }

    Behavior on wAnim {
        NumberAnimation {
            duration: Theme.speed
            easing.type: Theme.ease
        }
    }
    Behavior on hAnim {
        NumberAnimation {
            duration: Theme.speed
            easing.type: Theme.ease
        }
    }

    ClippingRectangle {
        id: body
        y: Theme.gap
        width: Math.round(root.wAnim)
        height: Math.round(root.hAnim)
        radius: Math.min(height / 2, Theme.radius)
        antialiasing: true
        color: Theme.bg

        Fade {
            id: idle
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round((Theme.h - height) / 2)
            width: row.width
            height: row.height
            shown: root.calm

            Row {
                id: row
                spacing: Theme.rowGap

                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    font.pixelSize: Theme.clockPx
                }

                Battery {
                    anchors.verticalCenter: parent.verticalCenter
                }

                Slot {
                    anchors.verticalCenter: parent.verticalCenter
                    shown: Mic.muted
                    onClicked: Mic.toggle()

                    MicOff {}
                }

                Slot {
                    anchors.verticalCenter: parent.verticalCenter
                    size: Theme.recordDot
                    shown: Record.active
                    onClicked: Record.stop()

                    Rectangle {
                        property real pulse: 1
                        anchors.fill: parent
                        radius: width / 2
                        color: Theme.red
                        antialiasing: true
                        opacity: Theme.dotLow + (1 - Theme.dotLow) * pulse

                        SequentialAnimation on pulse {
                            running: Record.active
                            loops: Animation.Infinite
                            NumberAnimation {
                                from: 1
                                to: 0
                                duration: Theme.pulse
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                from: 0
                                to: 1
                                duration: Theme.pulse
                                easing.type: Easing.InOutSine
                            }
                        }
                    }
                }
            }
        }

        Week {
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.body
            now: clock.date
            shown: root.hot && !root.full && root.calm && !root.media
            ready: !root.resizing
        }

        MediaPanel {
            id: tune
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.body
            shown: root.hot && !root.full && root.calm && root.media
            ready: !root.resizing
        }

        Calendar {
            id: cal
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.body
            now: clock.date
            shown: root.hot && root.full && root.calm
            ready: !root.resizing
        }

        Note {
            anchors.horizontalCenter: parent.horizontalCenter
            n: Notifs.current
            shown: root.alert
            ready: !root.resizing
        }

        Launch {
            id: launch
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.lpad
            shown: Launcher.open
            ready: !root.resizing
        }

        PowerMenu {
            id: power
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.pwPad
            shown: Power.open
            ready: !root.resizing
        }

        Wall {
            id: wall
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.wallPad
            shown: Wallpaper.open
            ready: !root.resizing
        }

        RecordMenu {
            id: rec
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.recordPad
            shown: Record.open
            ready: !root.resizing
        }

        NetMenu {
            id: net
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.netPad
            shown: Net.open
            ready: !root.resizing
        }

        Auth {
            id: auth
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.authPad
            shown: Polkit.open
            ready: !root.resizing
        }
    }
}
