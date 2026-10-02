import QtQuick

Rectangle {
    id: root
    property bool hovered: false
    property bool pressed: false
    property bool selected: false
    property color normalColor: Theme.chip
    property color hoverColor: Theme.tile
    property color pressColor: Theme.press
    property color selectedColor: Theme.accent

    antialiasing: true
    color: selected ? selectedColor : pressed ? pressColor : hovered ? hoverColor : normalColor

    Behavior on color {
        ColorAnimation {
            duration: Theme.feedback
            easing.type: Theme.ease
        }
    }
}
