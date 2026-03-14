pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    function clamp(val, min, max) {
        return Math.max(min, Math.min(max, val))
    }

    function toggle(model, index, currentValue, prop) {
        model.setProperty(index, prop, !currentValue)
    }

    Process {
        id: powerProfileProc
        command: ["bash", "-c", "powerprofilesctl get"]
        stdout: SplitParser {
            onRead: data => 
            PopupStates.power_profile = data.trim().charAt(0).toUpperCase() + data.trim().slice(1)
        }
    }

    function getPowerProfile() {
        powerProfileProc.running = false
        powerProfileProc.running = true
    }
}