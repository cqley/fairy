import QtQuick
import Quickshell.Services.UPower

Txt {
    visible: UPower.displayDevice.isLaptopBattery
    readonly property real pct: UPower.displayDevice.percentage
    readonly property bool charging: UPower.displayDevice.state === UPowerDeviceState.Charging
    readonly property bool low: pct <= Theme.batLow && !charging
    text: Math.round(pct * 100) + "%"
    color: low ? Theme.red : Theme.fg
    font.pixelSize: 13
}
