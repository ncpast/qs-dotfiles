pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
    id: root

    property string activeWindowTitle: "Desktop"
    property bool currentlySwitchingWorkspaces: false

    // Jump to a window (and its workspace) as soon as it becomes urgent.
    property bool focusUrgentWindows: true

    // workspace id -> unique window classes in that workspace, e.g. { "1": ["kitty", "codium"] }
    property var workspaceApps: ({})
    // workspace id -> true if it has at least one tiled (non-floating) window
    property var workspaceTiled: ({})

    Process {
        id: clientsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                var map = {}
                var tiled = {}
                try {
                    var clients = JSON.parse(text)
                    for (var i = 0; i < clients.length; i++) {
                        var c = clients[i]
                        if (!c.mapped || c.workspace.id <= 0 || c["class"] === "") continue
                        var list = map[c.workspace.id] || (map[c.workspace.id] = [])
                        if (list.indexOf(c["class"]) === -1) list.push(c["class"])
                        if (!c.floating) tiled[c.workspace.id] = true
                    }
                } catch (e) {}
                root.workspaceApps = map
                root.workspaceTiled = tiled
            }
        }
    }

    function refreshApps() { appsDebounce.restart() }

    Timer {
        id: appsDebounce
        interval: 60
        onTriggered: if (!clientsProc.running) clientsProc.running = true
    }

    Component.onCompleted: refreshApps()

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
                Hyprland.refreshWorkspaces()
            }
            if (event.name === "urgent" && root.focusUrgentWindows) {
                // data is the window address without the 0x prefix
                Quickshell.execDetached(["hyprctl", "dispatch",
                    "hl.dsp.focus({ window = \"address:0x" + event.data.trim() + "\" })"])
            }
            if (["openwindow", "closewindow", "movewindowv2", "workspacev2", "createworkspacev2",
                 "destroyworkspacev2"].indexOf(event.name) !== -1)
                root.refreshApps()
            if (event.name === "createworkspacev2" || event.name === "destroyworkspacev2"
                       || event.name === "moveworkspacev2") {
                Hyprland.refreshWorkspaces()
            }
        }
    }
}