import QtQuick

Item {
    id: root
    property bool shown
    opacity: 0
    visible: root.shown || opacity > 0

    states: State {
        name: "on"
        when: root.shown
        PropertyChanges { root.opacity: 1 }
    }

    transitions: [
        Transition {
            to: "on"
            NumberAnimation {
                property: "opacity"
                duration: Theme.speed
                easing.type: Theme.ease
            }
        },
        Transition {
            from: "on"
            NumberAnimation {
                property: "opacity"
                duration: Theme.fade
                easing.type: Theme.ease
            }
        }
    ]
}
