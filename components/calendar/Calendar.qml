import "../core"
import QtQuick

Fade {
    id: root
    property date now
    property int months: 0
    property int last: 0
    readonly property date view: new Date(now.getFullYear(), now.getMonth() + months, 1)
    readonly property int first: view.getDay()
    readonly property int rows: Math.ceil((first + new Date(view.getFullYear(), view.getMonth() + 1, 0).getDate()) / 7)

    width: col.width
    height: col.height

    onVisibleChanged: if (!visible) months = 0
    onMonthsChanged: {
        grid.y = months > last ? 10 : -10
        grid.opacity = 0
        last = months
        settle.restart()
    }

    ParallelAnimation {
        id: settle
        NumberAnimation { target: grid; property: "y"; to: 0; duration: Theme.glide; easing.type: Theme.ease }
        NumberAnimation { target: grid; property: "opacity"; to: 1; duration: Theme.glide; easing.type: Theme.ease }
    }

    Column {
        id: col
        spacing: 6

        Txt {
            x: 4
            text: Qt.formatDate(root.view, "MMMM yyyy").toLowerCase()
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }

        Item {
            width: Theme.gridW
            height: grid.height

            Grid {
                id: grid
                columns: 7

                Repeater {
                    model: 7

                    Txt {
                        required property int index
                        width: Theme.cellW
                        height: 16
                        horizontalAlignment: Text.AlignHCenter
                        text: "smtwtfs"[index]
                        color: index === 0 || index === 6 ? Theme.red : Theme.fg
                        opacity: 0.5
                        font.pixelSize: 10
                    }
                }

                Repeater {
                    model: root.rows * 7

                    Item {
                        required property int index
                        readonly property date d: new Date(root.view.getFullYear(), root.view.getMonth(), index - root.first + 1)
                        readonly property bool inMonth: d.getMonth() === root.view.getMonth()
                        readonly property bool today: d.getFullYear() === root.now.getFullYear() && d.getMonth() === root.now.getMonth() && d.getDate() === root.now.getDate()
                        readonly property bool weekend: index % 7 === 0 || index % 7 === 6

                        width: Theme.cellW
                        height: Theme.cellH
                        opacity: inMonth ? 1 : 0.25

                        Rectangle {
                            anchors.centerIn: parent
                            width: Theme.cellH
                            height: Theme.cellH
                            radius: Theme.cellH / 2
                            visible: today
                            color: Theme.accent
                            opacity: 0.15
                        }

                        Txt {
                            anchors.centerIn: parent
                            text: d.getDate()
                            color: today ? Theme.accent : weekend ? Theme.red : Theme.fg
                            font.weight: today ? Font.Bold : Font.Medium
                        }
                    }
                }
            }
        }
    }

    Wheel {
        anchors.fill: parent
        onStep: n => root.months += n
    }
}
