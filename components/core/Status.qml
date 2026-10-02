import QtQuick

Txt {
    id: root
    property string message: ""
    property bool error: false
    width: parent ? parent.width : implicitWidth
    height: Theme.stateH
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    text: root.message
    visible: root.message !== ""
    color: root.error ? Theme.red : Theme.fg
    opacity: root.error ? Theme.errorOpacity : Theme.stateOpacity
    font.pixelSize: Theme.statePx
}
