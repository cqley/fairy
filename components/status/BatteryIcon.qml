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

    width: shown && available ? Theme.batGap + Theme.batW + Theme.batNubGap + Theme.batNubW : 0
    height: Theme.batRowH
    visible: shown && available

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
            width: Math.round((body.width - Theme.batBorder * 2) * root.pct)
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
                        path: "M3.35 0L0.4 4.05H2.4L1.85 8L5.6 2.85H3.55L3.35 0Z"
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
