import "../core"
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets

Fade {
    id: root
    property var n
    property string summary
    property string body
    property string letter
    property string source
    property bool critical
    property bool battery
    property bool charging

    width: Theme.noteW
    height: Theme.noteH

    onNChanged: {
        if (!n) return
        summary = String(n.summary || "")
        body = String(n.body || "").replace(/^\s*<a[^>]*>.*?<\/a>\s*/, "").replace(/<[^>]*>/g, "")
        letter = ((n.appName || "?")[0] || "?").toLowerCase()
        critical = n.urgency === NotificationUrgency.Critical
        battery = !!n.system && n.kind === "battery"
        charging = battery && !!n.charging
        const image = String(n.image || "")
        const icon = String(n.appIcon || "")
        source = !battery && image !== ""
            ? Theme.url(image)
            : !battery && icon !== ""
                ? icon.startsWith("/") || /^[a-z][a-z0-9+.-]*:/i.test(icon) ? Theme.url(icon) : Quickshell.iconPath(icon, true)
                : ""
    }

    ClippingRectangle {
        id: chip
        x: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 28
        height: 28
        radius: 14
        color: root.critical ? Theme.red : Theme.chip

        Image {
            id: img
            anchors.fill: parent
            source: root.source
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(56, 56)
            visible: root.source !== "" && status === Image.Ready
        }

        Item {
            anchors.centerIn: parent
            width: Theme.noteBatW
            height: Theme.noteBatH
            visible: root.battery

            Rectangle {
                id: batteryBody
                width: Theme.noteBatW - Theme.noteBatNubW - Theme.noteBatGap
                height: Theme.noteBatH
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                radius: Theme.noteBatRadius
                color: Theme.batGreen
                border.color: Theme.fg
                border.width: Theme.noteBatBorder
                antialiasing: true
            }

            Rectangle {
                anchors.left: batteryBody.right
                anchors.leftMargin: Theme.noteBatGap
                anchors.verticalCenter: batteryBody.verticalCenter
                width: Theme.noteBatNubW
                height: Theme.noteBatNubH
                radius: width / 2
                color: Theme.noteBatNubColor
                antialiasing: true
            }

            Shape {
                anchors.centerIn: batteryBody
                width: Theme.noteBatBoltW
                height: Theme.noteBatBoltH
                visible: root.charging
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: Theme.fg
                    strokeColor: "transparent"
                    strokeWidth: 0

                    PathSvg {
                        path: "M2.25 0L0.45 2.65H1.72L1.45 6L3.6 3.05H2.2L2.25 0Z"
                    }
                }
            }
        }

        Txt {
            anchors.centerIn: parent
            text: root.letter
            visible: !root.battery && img.status !== Image.Ready
            font.pixelSize: 12
            font.weight: Font.Bold
        }
    }

    Column {
        anchors.left: chip.right
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Txt {
            width: parent.width
            text: root.summary
            elide: Text.ElideRight
            maximumLineCount: 1
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }

        Txt {
            width: parent.width
            text: root.body
            visible: text !== ""
            elide: Text.ElideRight
            maximumLineCount: 1
            opacity: 0.6
            font.pixelSize: 10
        }
    }
}
