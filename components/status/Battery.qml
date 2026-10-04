pragma Singleton
import "../core"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root

    property bool shown: true

    readonly property var device: UPower.displayDevice
    readonly property bool available: device.ready && device.isLaptopBattery
    readonly property real pct: {
        const value = Number(device.percentage)
        return isFinite(value) ? Math.max(0, Math.min(1, value)) : 0
    }
    readonly property color tone: root.pct <= Theme.batRedAt
        ? Theme.batRed
        : root.pct <= Theme.batYellowAt ? Theme.batYellow : Theme.batGreen
    readonly property bool pluggedIn: root.available && (
        device.state === UPowerDeviceState.PendingCharge ||
        device.state === UPowerDeviceState.Charging ||
        device.state === UPowerDeviceState.FullyCharged
    )

    function toggle() {
        root.shown = !root.shown
    }

    IpcHandler {
        target: "battery"
        function toggle(): void { root.toggle() }
        function status(): string { return root.shown ? "on" : "off" }
    }
}
