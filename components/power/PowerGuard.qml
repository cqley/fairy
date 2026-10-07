import "../core"
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property bool active: false
    property real progress: 0
    readonly property real stroke: Theme.powerGuardBorderWidth
    readonly property real inset: stroke + 0.5
    readonly property real pathWidth: Math.max(0, width - inset * 2)
    readonly property real pathHeight: Math.max(0, height - inset * 2)
    readonly property real radius: Math.max(0, Math.min(Theme.pwTileRadius - inset, Math.min(pathWidth, pathHeight) / 2))
    readonly property real length: 2 * (pathWidth + pathHeight - 2 * radius) + 2 * Math.PI * radius
    readonly property real visibleLength: Math.max(0.01, root.progress * root.length)
    readonly property real gapLength: Math.max(0.01, root.length - root.visibleLength)

    anchors.fill: parent
    visible: root.active && root.progress > 0.001
    z: 3

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: path
            strokeWidth: root.stroke
            strokeColor: Theme.powerGuardColor
            fillColor: "transparent"
            strokeStyle: ShapePath.DashLine
            dashPattern: [root.visibleLength / root.stroke, root.gapLength / root.stroke]
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            pathHints: ShapePath.PathNonIntersecting

            PathSvg {
                path: {
                    const l = root.inset
                    const t = root.inset
                    const r = root.inset + root.pathWidth
                    const b = root.inset + root.pathHeight
                    const q = root.radius
                    const c = root.inset + root.pathWidth / 2
                    return "M " + c + " " + b +
                        " L " + (l + q) + " " + b +
                        " A " + q + " " + q + " 0 0 1 " + l + " " + (b - q) +
                        " L " + l + " " + (t + q) +
                        " A " + q + " " + q + " 0 0 1 " + (l + q) + " " + t +
                        " L " + (r - q) + " " + t +
                        " A " + q + " " + q + " 0 0 1 " + r + " " + (t + q) +
                        " L " + r + " " + (b - q) +
                        " A " + q + " " + q + " 0 0 1 " + (r - q) + " " + b +
                        " L " + c + " " + b +
                        " Z"
                }
            }
        }
    }
}
