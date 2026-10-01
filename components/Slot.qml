import QtQuick

Item {
    id: root
    property bool shown: false
    property int size: Theme.micS
    default property alias content: holder.data
    signal clicked

    width: shown ? size : 0
    height: size
    clip: true


    Item {
        id: holder
        property real enter: root.shown ? 1 : 0
        anchors.centerIn: parent
        width: root.size
        height: root.size
        scale: Theme.slotScale + (1 - Theme.slotScale) * enter
        opacity: enter

        Behavior on enter {
            NumberAnimation {
                duration: Theme.slide
                easing.type: Theme.ease
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -Theme.slotHit
        enabled: root.shown
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
