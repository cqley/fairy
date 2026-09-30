import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

Fade {
    id: root
    property var n
    property string summary
    property string body
    property string letter
    property string source
    property bool critical

    width: Theme.noteW
    height: Theme.noteH

    onNChanged: {
        if (!n) return
        summary = n.summary
        body = n.body.replace(/^\s*<a[^>]*>.*?<\/a>\s*/, "").replace(/<[^>]*>/g, "")
        letter = (n.appName || "?")[0].toLowerCase()
        critical = n.urgency === NotificationUrgency.Critical
        source = n.image !== "" ? n.image : n.appIcon.startsWith("/") ? "file://" + n.appIcon : Quickshell.iconPath(n.appIcon, true)
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
            visible: status === Image.Ready
        }

        Txt {
            anchors.centerIn: parent
            text: root.letter
            visible: img.status !== Image.Ready
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

