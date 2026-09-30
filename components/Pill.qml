import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root
    property bool full: false
    readonly property bool hot: hover.hovered
    readonly property bool modal: Launcher.open || Power.open || Wallpaper.open || Polkit.open
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
            if (root.alert) Notifs.dismiss()
            else if (!root.modal && root.hot) root.full = !root.full
        }
    }

    Binding {
        target: Notifs
        property: "hovered"
        value: root.hot || root.modal
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Binding {
        target: root
        property: "wAnim"
        value: Polkit.open ? Theme.authW : root.alert ? Theme.noteW : Launcher.open ? Theme.launchW : Power.open ? Theme.powerW : Wallpaper.open ? Theme.wallW : root.hot ? (root.media && !root.full ? Theme.mediaPillW : Theme.openW) : Math.max(Theme.w, root.calm ? idle.width + Theme.pad : Theme.w)
    }

    Binding {
        target: root
        property: "hAnim"
        value: Polkit.open ? auth.y + auth.height + Theme.authPad : root.alert ? Theme.noteH : Launcher.open ? launch.y + launch.height + Theme.lpad : Power.open ? power.y + power.height + Theme.pwPad : Wallpaper.open ? wall.y + wall.height + Theme.wallPad : root.full ? cal.y + cal.height + Theme.pad : root.hot ? (root.media ? tune.y + tune.height + Theme.pad : Theme.openH) : Theme.h
    }

    Behavior on wAnim {
        NumberAnimation { duration: Theme.speed; easing.type: Theme.ease }
    }
    Behavior on hAnim {
        NumberAnimation { duration: Theme.speed; easing.type: Theme.ease }
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
                spacing: 8

                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    font.pixelSize: 14
                }

                Battery {
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Week {
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.body
            now: clock.date
            shown: root.hot && !root.full && root.calm && !root.media
        }

        MediaPanel {
            id: tune
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.body
            shown: root.hot && !root.full && root.calm && root.media
        }

        Calendar {
            id: cal
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.body
            now: clock.date
            shown: root.hot && root.full && root.calm
        }

        Note {
            anchors.horizontalCenter: parent.horizontalCenter
            n: Notifs.current
            shown: root.alert
        }

        Launch {
            id: launch
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.lpad
            shown: Launcher.open
        }

        PowerMenu {
            id: power
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.pwPad
            shown: Power.open
        }

        Wall {
            id: wall
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.wallPad
            shown: Wallpaper.open
        }

        Auth {
            id: auth
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.authPad
            shown: Polkit.open
        }
    }
}

