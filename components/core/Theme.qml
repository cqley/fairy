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
    readonly property int recordStopGrace: 3000
    readonly property int netW: 320
    readonly property int netPad: 12
    readonly property int netRowH: 36
    readonly property int netRows: 6
    readonly property int netFieldH: 34
    readonly property int netToggleW: 36
    readonly property int netToggleH: 20
    readonly property int netKnob: 14
    readonly property color bg: "#000000"
    readonly property color fg: "#ffffff"
    readonly property color chip: "#1c1c1e"
    readonly property color tile: "#2c2c2e"
    readonly property color accent: "#f2b8e2"
    readonly property color red: "#e5534b"

    readonly property int listGap: 6
    readonly property int rowX: 18
    readonly property int rowR: 14
    readonly property int markW: 3
    readonly property int markX: 5
    readonly property int fsXS: 10
    readonly property int fsS: 11
    readonly property int fsM: 12
    readonly property int fsL: 13

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
    readonly property int micS: 12
    readonly property int clockPx: 14
    readonly property int idleOffsetX: 0
    readonly property int idleOffsetY: 0
    readonly property int clockOffsetX: 0
    readonly property int clockOffsetY: 0
    readonly property int batteryOffsetX: 0
    readonly property int batteryOffsetY: 0
    readonly property int micOffsetX: 0
    readonly property int micOffsetY: 0
    readonly property int recordOffsetX: 0
    readonly property int recordOffsetY: 0
    readonly property int batRowH: 16
    readonly property int batW: 21
    readonly property int batH: 11
    readonly property int batBorder: 1
    readonly property int batNubW: 2
    readonly property int batNubH: 5
    readonly property int batNubGap: 1
    readonly property int batGap: 8
    readonly property int batIconW: batGap + batW + batNubGap + batNubW
    readonly property int batRadius: 4
    readonly property int batFillRadius: 3
    readonly property int batBoltW: 5
    readonly property int batBoltH: 7
    readonly property real batPopScale: slotScale
    readonly property real batBoltScale: 0.75
    readonly property int batBoltDuration: 140
    readonly property int noteBatW: 16
    readonly property int noteBatH: 10
    readonly property int noteBatNubW: 2
    readonly property int noteBatNubH: 4
    readonly property int noteBatGap: 1
    readonly property int noteBatBorder: 1
    readonly property int noteBatRadius: 3
    readonly property int noteBatBoltW: 4
    readonly property int noteBatBoltH: 6
    readonly property color batRed: "#ff3b30"
    readonly property color batYellow: "#ffcc00"
    readonly property color batGreen: "#34c759"
    readonly property int rowGap: 8
    readonly property int idlePopDuration: speed
    readonly property int pulse: 1400
    readonly property int blink: 700
    readonly property int slotHit: 6
    readonly property real slotScale: 0.7
    readonly property real dotLow: 0.65

    readonly property int cellW: 30
    readonly property int cellH: 24
    readonly property int stripH: 40
    readonly property int gridW: cellW * 7
    readonly property int body: h + 2
    readonly property int zone: gap + h

    readonly property int speed: 300
    readonly property int fade: 60
    readonly property int glide: 240
    readonly property int fast: 60
    readonly property int dwell: 5000
    readonly property int dwellCritical: 12000
    readonly property real batRedAt: 0.15
    readonly property real batYellowAt: 0.25
    readonly property int ease: Easing.OutCubic

    function url(path) {
        return "file://" + path.split("/").map(encodeURIComponent).join("/")
    }
}
