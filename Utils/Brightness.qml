pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Screen brightness as 0-100, on the same curve as the Hyprland keybinds
// (`brightnessctl -e4`), so each key press moves the value by an even 5%.
Singleton {
    id: root

    property int percent: 0
    property bool loaded: false

    // Lowest raw backlight value the keybinds allow (brightnessctl -n2)
    readonly property int minRaw: 2

    // Emitted whenever the backlight is adjusted (even if the value didn't change,
    // e.g. pressing "brighter" at maximum), but not for the initial read.
    signal adjusted()

    // The kernel emits a udev "change" event each time the backlight is written.
    Process {
        command: ["stdbuf", "-oL", "udevadm", "monitor", "--udev", "--subsystem-match=backlight"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                if (data.includes(" change ")) refresh.restart()
            }
        }
    }

    Timer {
        id: refresh
        interval: 30
        onTriggered: if (!readProc.running) readProc.running = true
    }

    Process {
        id: readProc
        command: ["brightnessctl", "-m"]
        stdout: SplitParser {
            // device,class,current,percent,max
            onRead: data => {
                const f = data.split(",")
                const cur = parseInt(f[2]), max = parseInt(f[4])
                if (!(max > 0)) return
                // Keybinds use `-n2` (never go below raw value 2), which sits at
                // 100*(2/max)^0.25 ~ 27% on the curve. Rescale so that floor reads 0%.
                const curve = v => 100 * Math.pow(v / max, 0.25)
                const floor = curve(root.minRaw)
                root.percent = Math.max(0, Math.min(100, Math.round(100 * (curve(cur) - floor) / (100 - floor))))
                if (root.loaded) root.adjusted()
                root.loaded = true
            }
        }
    }

    Component.onCompleted: readProc.running = true
}
