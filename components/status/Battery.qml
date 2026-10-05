pragma Singleton
import "../core"
import "../notifications"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root

    property bool shown: true
    property string lastPowerConnection: ""

    readonly property var device: UPower.displayDevice
    readonly property bool available: !!device && device.ready && device.isLaptopBattery
    readonly property real pct: {
        if (!root.available)
            return 0
        const value = Number(root.device.percentage)
        return isFinite(value) ? Math.max(0, Math.min(1, value)) : 0
    }
    readonly property int percent: Math.round(root.pct * 100)
    readonly property color tone: root.pct <= Theme.batRedAt
        ? Theme.batRed
        : root.pct <= Theme.batYellowAt ? Theme.batYellow : Theme.batGreen
    readonly property string powerConnection: root.connectionForState(root.available ? root.device.state : null)
    readonly property bool pluggedIn: root.powerConnection === "external"

    function connectionForState(state) {
        switch (state) {
        case UPowerDeviceState.PendingCharge:
        case UPowerDeviceState.Charging:
        case UPowerDeviceState.FullyCharged:
            return "external"
        case UPowerDeviceState.PendingDischarge:
        case UPowerDeviceState.Discharging:
        case UPowerDeviceState.Empty:
            return "battery"
        default:
            return ""
        }
    }

    function syncPowerConnection() {
        const state = root.powerConnection
        if (state === "" || state === root.lastPowerConnection)
            return

        const previous = root.lastPowerConnection
        root.lastPowerConnection = state
        if (previous === "")
            return

        Notifs.pushSystem(
            state === "external" ? "charger connected" : "charger disconnected",
            state === "external"
                ? root.device.state === UPowerDeviceState.FullyCharged
                    ? `battery full · ${root.percent}%`
                    : `battery charging · ${root.percent}%`
                : `running on battery · ${root.percent}%`,
            state === "external"
        )
    }

    function resetPowerConnection() {
        root.lastPowerConnection = ""
        root.syncPowerConnection()
    }

    function toggle() {
        root.shown = !root.shown
    }

    Component.onCompleted: root.syncPowerConnection()
    onDeviceChanged: root.resetPowerConnection()

    Connections {
        target: root.device
        function onReadyChanged() { root.syncPowerConnection() }
        function onIsLaptopBatteryChanged() { root.syncPowerConnection() }
        function onStateChanged() { root.syncPowerConnection() }
    }

    IpcHandler {
        target: "battery"
        function toggle(): void { root.toggle() }
        function status(): string { return root.shown ? "on" : "off" }
    }
}
