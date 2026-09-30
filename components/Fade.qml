import QtQuick

Item {
    id: root
    property bool shown

    opacity: 0
    visible: opacity > 0

    states: State {
        name: "on"
        when: root.shown
        PropertyChanges { root.opacity: 1 }
    }

    transitions: [
        Transition {
            to: "on"
            SequentialAnimation {
                PauseAnimation { duration: Theme.fade }
                NumberAnimation { property: "opacity"; duration: Theme.speed; easing.type: Easing.InCubic }
            }
        },
        Transition {
            from: "on"
            NumberAnimation { property: "opacity"; duration: Theme.fade; easing.type: Theme.ease }
        }
    ]
}

