import "../core"
import QtQuick

Item {
    width: 14
    height: 12

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 8
        height: 6
        radius: 4
        color: "transparent"
        border.width: 1.4
        border.color: Theme.fg
        antialiasing: true
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 4
        width: 10
        height: 8
        radius: 2
        color: Theme.fg
        antialiasing: true
    }
}
