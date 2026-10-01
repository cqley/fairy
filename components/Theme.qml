pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property string screen: "HDMI-A-1"
    readonly property string font: "sans-serif"
    readonly property var terminal: ["sh", "-c", 'for t in "$TERMINAL" alacritty kitty foot ghostty wezterm xterm; do command -v "$t" >/dev/null 2>&1 || continue; case $t in kitty) exec kitty "$@";; wezterm) exec wezterm start -- "$@";; *) exec "$t" -e "$@";; esac; done', "sh"]
    readonly property string wallDir: "file:///home/cat/pictures/wallpapers"
    readonly property var wallCmd: ["colors"]
    readonly property string recordDir: "/home/cat/videos/records"
    readonly property string recordBin: ""
    readonly property string recordBackend: ""
    readonly property int recordFps: 60
    readonly property int recordDot: 7
    readonly property int recordW: 300
    readonly property int recordPad: 12
    readonly property int recordRowH: 34
    readonly property int recordRows: 6
    readonly property color bg: "#000000"
    readonly property color fg: "#ffffff"
    readonly property color chip: "#1c1c1e"
    readonly property color tile: "#2c2c2e"
    readonly property color accent: "#f2b8e2"
    readonly property color red: "#e5534b"

    readonly property int gap: 6
    readonly property int pad: 16
    readonly property int w: 64
    readonly property int h: 28
    readonly property int openW: 252
    readonly property int openH: 80
    readonly property int noteW: 264
    readonly property int noteH: 48
    readonly property int radius: 28

    readonly property int launchW: 340
    readonly property int lpad: 8
    readonly property int rowH: 38
    readonly property int rows: 5
    readonly property int searchH: 32

    readonly property int pwW: 68
    readonly property int pwH: 66
    readonly property int pwGap: 8
    readonly property int pwPad: 10
    readonly property int pwN: 5
    readonly property int powerW: pwW * pwN + pwGap * (pwN - 1) + pwPad * 2
    readonly property int powerH: pwH + pwPad * 2

    readonly property int wallPad: 14
    readonly property int thumbW: 120
    readonly property int thumbH: 68
    readonly property int thumbGap: 16
    readonly property int wallN: 5
    readonly property int wallW: thumbW * wallN + thumbGap * (wallN - 1) + wallPad * 2

    readonly property int authW: 380
    readonly property int authPad: 16
    readonly property int authFieldH: 40
    readonly property int authFieldR: 12
    readonly property int authBtnH: 34
    readonly property int authIcon: 32

    readonly property int mediaPillW: 268
    readonly property int mediaW: mediaPillW - 2 * pad
    readonly property int mediaGap: 8
    readonly property int artS: 40
    readonly property int ctlS: 26
    readonly property int playS: 30
    readonly property int glyphS: 14
    readonly property int playGlyph: 14
    readonly property int barH: 3
    readonly property int timeH: 10

    readonly property int cellW: 30
    readonly property int cellH: 24
    readonly property int stripH: 40
    readonly property int gridW: cellW * 7
    readonly property int body: h + 2
    readonly property int zone: gap + h

    readonly property int speed: 300
    readonly property int fade: 60
    readonly property int glide: 240
    readonly property int dwell: 5000
    readonly property int dwellCritical: 12000
    readonly property real batLow: 0.2
    readonly property int ease: Easing.OutCubic
}
