import "../core"
import QtQuick

Item {
    id: root

    property url source
    property string fallbackText: "?"
    property bool selected: false
    property bool hovered: false
    property bool pressed: false
    property int token: 0
    property string wantedSource: ""
    property bool showingFront: true
    property bool hasImage: false
    property bool failed: false
    property real frontOpacity: 0
    property real backOpacity: 0
    property real fallbackOpacity: 1

    width: Theme.launchIconBox
    height: Theme.launchIconBox

    function activeImage() {
        return root.showingFront ? front : back
    }

    function pendingImage() {
        return root.showingFront ? back : front
    }

    function commit(image, id) {
        if (id !== root.token || String(image.source || "") !== root.wantedSource || image.status !== Image.Ready)
            return
        root.failed = false
        root.hasImage = true
        if (image === front) {
            root.frontOpacity = 1
            root.backOpacity = 0
            root.showingFront = true
        } else {
            root.frontOpacity = 0
            root.backOpacity = 1
            root.showingFront = false
        }
        root.fallbackOpacity = 0
    }

    function fail(image, id) {
        if (id !== root.token || String(image.source || "") !== root.wantedSource)
            return
        root.failed = true
        root.hasImage = false
        root.frontOpacity = 0
        root.backOpacity = 0
        root.fallbackOpacity = 1
    }

    function request() {
        const wanted = String(root.source || "")
        const id = ++root.token
        root.wantedSource = wanted
        root.failed = false

        if (wanted === "") {
            root.hasImage = false
            root.frontOpacity = 0
            root.backOpacity = 0
            root.fallbackOpacity = 1
            return
        }

        const active = root.activeImage()
        if (root.hasImage && String(active.source || "") === wanted && active.status === Image.Ready)
            return

        const next = root.pendingImage()
        next.requestToken = id
        if (String(next.source || "") === wanted && next.status === Image.Error) {
            next.source = ""
            next.source = wanted
        } else {
            next.source = wanted
        }

        if (next.status === Image.Ready)
            root.commit(next, id)
    }

    function cancel() {
        root.token++
    }

    onSourceChanged: request()
    Component.onCompleted: request()

    Rectangle {
        id: frame
        anchors.fill: parent
        radius: Theme.launchIconRadius
        color: root.selected ? Theme.launchIconSelectedFill : Theme.launchIconFill
        border.color: root.selected ? Theme.accent : root.hovered ? Theme.launchIconHoverBorder : Theme.launchIconBorder
        border.width: Theme.launchIconBorderWidth
        antialiasing: true
        transformOrigin: Item.Center
        scale: root.pressed ? Theme.feedbackPressScale : root.selected ? Theme.launchIconSelectedScale : root.hovered ? Theme.feedbackHoverScale : 1

        Behavior on scale { NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease } }
        Behavior on color { ColorAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease } }
        Behavior on border.color { ColorAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease } }

        Image {
            id: front
            property int requestToken: 0
            anchors.centerIn: parent
            width: Theme.launchIconSize
            height: Theme.launchIconSize
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            sourceSize: Qt.size(Theme.launchIconSourceSize, Theme.launchIconSourceSize)
            smooth: true
            opacity: root.frontOpacity

            Behavior on opacity { NumberAnimation { duration: Theme.launchIconCrossfade; easing.type: Theme.ease } }
            onStatusChanged: {
                if (status === Image.Ready)
                    root.commit(front, requestToken)
                else if (status === Image.Error)
                    root.fail(front, requestToken)
            }
        }

        Image {
            id: back
            property int requestToken: 0
            anchors.centerIn: parent
            width: Theme.launchIconSize
            height: Theme.launchIconSize
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            sourceSize: Qt.size(Theme.launchIconSourceSize, Theme.launchIconSourceSize)
            smooth: true
            opacity: root.backOpacity

            Behavior on opacity { NumberAnimation { duration: Theme.launchIconCrossfade; easing.type: Theme.ease } }
            onStatusChanged: {
                if (status === Image.Ready)
                    root.commit(back, requestToken)
                else if (status === Image.Error)
                    root.fail(back, requestToken)
            }
        }

        Txt {
            anchors.centerIn: parent
            text: root.fallbackText
            opacity: root.fallbackOpacity
            visible: root.failed || opacity > 0.01
            font.pixelSize: Theme.launchFallbackPx
            font.weight: Font.Bold

            Behavior on opacity { NumberAnimation { duration: Theme.launchIconCrossfade; easing.type: Theme.ease } }
        }
    }
}
