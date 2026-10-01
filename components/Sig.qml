import QtQuick

Row {
    id: root
    property int level: 0
    spacing: 2

    Repeater {
        model: 4

        Rectangle {
            required property int index
            anchors.bottom: parent.bottom
            width: 3
            height: 4 + index * 2
            radius: 1
            color: Theme.fg
            opacity: root.level > index ? 0.9 : 0.2
            antialiasing: true
        }
    }
}
