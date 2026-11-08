pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property string activeWindowTitle: "Desktop"
    property bool currentlySwitchingWorkspaces: false

    Timer {
        id: wsTimer
        interval: 1500
        onTriggered: root.currentlySwitchingWorkspaces = false
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "activewindow") {
                var parts = event.data.split(",")
                var title = parts.slice(1).join(",")
                root.activeWindowTitle = title.length > 0 ? title : "Desktop"
            } else if (event.name === "workspacev2" || event.name === "workspace") {
                root.currentlySwitchingWorkspaces = true
                wsTimer.restart()
            }
        }
    }
}