pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property bool any: Launcher.open || Power.open || Wallpaper.open || Polkit.open || Record.open || Net.open

    function all() {
        return { launcher: Launcher, power: Power, wallpaper: Wallpaper, record: Record, net: Net }
    }

    function close(except) {
        const m = all()
        for (const k in m)
            if (k !== except)
                m[k].open = false
    }

    function claim(name) {
        if (Polkit.open)
            all()[name].open = false
        else
            close(name)
    }
}
