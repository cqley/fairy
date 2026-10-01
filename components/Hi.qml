import QtQuick

Rectangle {
    id: root
    required property var pick
    required property int row
    property color mark: Theme.accent

    y: pick.sel * row
    height: row
    radius: height / 2
    color: Theme.chip
    antialiasing: true

    Behavior on y {
        enabled: !root.pick.snap
        NumberAnimation {
            duration: root.pick.dur
            easing.type: Theme.ease
        }
    }

    Rectangle {
        x: Theme.markX
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.markW
        height: parent.height / 2 - 1
        radius: width / 2
        color: root.mark
    }
}
