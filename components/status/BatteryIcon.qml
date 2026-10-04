import "../core"
import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property bool shown: true
    property bool available: false
    property real pct: 0
    property color tone: Theme.batGreen
    property bool pluggedIn: false

    readonly property bool visibleState: root.shown && root.available

    width: root.visibleState ? Theme.batIconW : 0
    height: Theme.batRowH
    visible: root.visibleState

    Rectangle {
        id: body
        width: Theme.batW
        height: Theme.batH
        anchors.centerIn: parent
        radius: Theme.batRadius
        color: Theme.bg
        antialiasing: true

        Rectangle {
            x: Theme.batBorder
            y: Theme.batBorder
            width: root.pct > 0 ? Math.max(1, Math.round((body.width - Theme.batBorder * 2) * root.pct)) : 0
            height: body.height - Theme.batBorder * 2
            radius: Theme.batFillRadius
            color: root.tone
            antialiasing: true
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            radius: body.radius
            border.color: Theme.fg
            border.width: Theme.batBorder
            antialiasing: true

            Shape {
                anchors.centerIn: parent
                width: Theme.batBoltW
                height: Theme.batBoltH
                visible: root.pluggedIn
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: Theme.fg
                    strokeColor: "transparent"
                    strokeWidth: 0

                    PathSvg {
                        path: "M2.8 0L0.55 3.1H2.1L1.72 7L4.35 3.3H2.75L2.8 0Z"
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.left: body.right
        anchors.leftMargin: Theme.batNubGap
        anchors.verticalCenter: body.verticalCenter
        width: Theme.batNubW
        height: Theme.batNubH
        radius: Theme.batNubW / 2
        color: root.tone
        antialiasing: true
    }
}
