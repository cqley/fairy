import "../core"
import QtQuick
import QtQuick.Shapes
import Quickshell

Fade {
    id: root
    readonly property var flow: Polkit.flow
    readonly property string lockPath: "M5 11H19A2 2 0 0 1 21 13V20A2 2 0 0 1 19 22H5A2 2 0 0 1 3 20V13A2 2 0 0 1 5 11ZM7 11V7A5 5 0 0 1 17 7V11"

    width: Theme.authW - 2 * Theme.authPad
    height: col.height
    focus: shown

    function submit() {
        if (!flow || !flow.isResponseRequired) return
        flow.submit(input.text)
        input.text = ""
        input.forceActiveFocus()
    }

    function cancel() {
        Polkit.cancel()
        input.text = ""
    }

    onVisibleChanged: {
        input.text = ""
        if (visible) {
            forceActiveFocus()
            input.forceActiveFocus()
        }
    }

    Connections {
        target: Polkit
        function onOpenChanged() {
            input.text = ""
            if (Polkit.open) {
                root.forceActiveFocus()
                input.forceActiveFocus()
            }
        }
    }

    Connections {
        target: Polkit.flow
        function onIsResponseRequiredChanged() {
            input.text = ""
            if (Polkit.flow && Polkit.flow.isResponseRequired) input.forceActiveFocus()
        }
        function onFailedChanged() {
            if (Polkit.flow && Polkit.flow.failed) input.forceActiveFocus()
        }
    }

    Keys.onPressed: e => {
        if (e.key === Qt.Key_Escape) {
            root.cancel()
            e.accepted = true
        }
    }

    Column {
        id: col
        width: parent.width
        spacing: 12

        Row {
            spacing: 10

            Rectangle {
                width: Theme.authIcon
                height: Theme.authIcon
                radius: Theme.authFieldR - 2
                color: Theme.chip

                Shape {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    scale: 16 / 24
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        strokeWidth: 1.8
                        strokeColor: Theme.fg
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        joinStyle: ShapePath.RoundJoin
                        PathSvg { path: root.lockPath }
                    }
                }
            }

            Txt {
                anchors.verticalCenter: parent.verticalCenter
                text: "authentication required"
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }
        }

        Txt {
            width: parent.width
            text: root.flow ? (root.flow.message || "").toLowerCase() : ""
            wrapMode: Text.Wrap
            font.pixelSize: 13
        }

        Txt {
            width: parent.width
            visible: text !== ""
            text: root.flow ? (root.flow.actionId || "") : ""
            elide: Text.ElideMiddle
            opacity: 0.4
            font.pixelSize: 11
        }

        Txt {
            width: parent.width
            visible: !!root.flow && (root.flow.failed || (root.flow.supplementaryIsError && root.flow.supplementaryMessage !== ""))
            text: root.flow && root.flow.supplementaryIsError && root.flow.supplementaryMessage !== "" ? root.flow.supplementaryMessage.toLowerCase() : "authentication failed, try again"
            color: Theme.red
            wrapMode: Text.Wrap
            font.pixelSize: 12
        }

        Rectangle {
            width: parent.width
            height: Theme.authFieldH
            radius: Theme.authFieldR
            color: Theme.chip

            Shape {
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                height: 24
                scale: 16 / 24
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeWidth: 1.8
                    strokeColor: Theme.fg
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    PathSvg { path: root.lockPath }
                }
            }

            TextInput {
                id: input
                x: 40
                width: parent.width - 52
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.fg
                selectionColor: Theme.accent
                selectedTextColor: Theme.bg
                echoMode: root.flow && root.flow.responseVisible ? TextInput.Normal : TextInput.Password
                selectByMouse: true
                clip: true
                font.family: Theme.font
                font.pixelSize: 13
                font.weight: Font.Medium
                enabled: !!root.flow && root.flow.isResponseRequired
                onAccepted: root.submit()
            }

            Txt {
                x: input.x
                anchors.verticalCenter: parent.verticalCenter
                text: "password"
                visible: input.text === ""
                opacity: 0.35
                font.pixelSize: 13
            }
        }

        Item {
            width: parent.width
            height: Theme.authBtnH

            Row {
                anchors.right: parent.right
                spacing: 8

                Rectangle {
                    width: Math.round(cancelTxt.width + 28)
                    height: Theme.authBtnH
                    radius: Theme.authBtnH / 2
                    color: Theme.chip

                    Txt {
                        id: cancelTxt
                        anchors.centerIn: parent
                        text: "cancel"
                        font.pixelSize: 13
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.cancel()
                    }
                }

                Rectangle {
                    width: Math.round(okTxt.width + 28)
                    height: Theme.authBtnH
                    radius: Theme.authBtnH / 2
                    color: Theme.accent
                    opacity: input.text.length > 0 ? 1 : 0.45

                    Txt {
                        id: okTxt
                        anchors.centerIn: parent
                        text: "authenticate"
                        color: Theme.bg
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: input.text.length > 0
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.submit()
                    }
                }
            }
        }
    }
}
