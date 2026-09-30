import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property string path
    property bool solid: false
    property int dx: 0
    readonly property color ink: solid ? Theme.bg : Theme.fg
    signal clicked

    width: solid ? Theme.playS : Theme.ctlS
    height: width
    opacity: !enabled ? 0.3 : solid || area.containsMouse ? 1 : 0.75

    Behavior on opacity { NumberAnimation { duration: Theme.fade } }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.accent
        visible: root.solid
        antialiasing: true
    }

    Shape {
        x: Math.round((root.width - width) / 2) + root.dx
        y: Math.round((root.height - height) / 2)
        width: 24
        height: 24
        scale: (root.solid ? Theme.playGlyph : Theme.glyphS) / 24
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 2
            strokeColor: root.ink
            fillColor: root.solid ? root.ink : "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg { path: root.path }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

