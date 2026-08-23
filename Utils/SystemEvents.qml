pragma Singleton
import QtQuick
import Quickshell

QtObject {
    property bool activeWindowFloating: false

    Process {
        id: activeWindowCheck
        command: ["hyprctl", "activewindow", "-j"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text)
                    root.activeWindowFloating = data.floating === true
                } catch (e) {
                    root.activeWindowFloating = false
                }
            }
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "activewindow" || event.name === "changefloatingmode") {
                activeWindowCheck.running = true
            }
        }
    }
}