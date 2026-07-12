import Quickshell
import QtQuick
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import QtQuick.Layouts
import Quickshell.Wayland
import "../Theme" 
import "../Widgets"
import "../Utils"
import "../Widgets/MenuBar"

PanelWindow {
    id: topBar
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top;

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 33

    ActiveWindow {
        anchors.centerIn: parent
        //anchors.verticalCenterOffset: -Theme.active_window_name_offset - 3
    }

    Row {
        x: Theme.left_panel_width + Theme.concave_radius
        id: sensors
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height - 10
        spacing: 7

        Sensor {
            name : "battery"
            icon: ""
        }

        Sensor {
            name : "cpu"
            //icon: ""
            iconSizeOffset: 5
        }

        Sensor {
            name : "gpu"
            //icon: "󰾲"
        }

        SystemButtons {}
    }

    Row {
        anchors.right: parent.right
        height: parent.height
        spacing: 15

        // Date

        Text {
            id: dateText
            anchors.verticalCenter: parent.verticalCenter
            
            // Uses Qt's built-in formatting tool. Examples: 
            // "dd-MM-yyyy" -> 08-07-2026
            // "dd MMM yyyy" -> 08 Jul 2026
            text: Qt.formatDateTime(new Date(), "ddd d MMM h:mm")
            
            color: Theme.accent
            font.weight: Font.DemiBold
            font.pixelSize: 13
            font.family: "Inter"

            Timer {
                interval: 10000 
                running: true
                repeat: true
                onTriggered: dateText.text = Qt.formatDateTime(new Date(), "ddd d MMM h:mm")
            }
        }

        // Wifi

        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.family: 'JetBrainsMono Nerd Font'
            font.pixelSize: 16
            text: Monitors.network_icon
            color: Theme.accent
        }

        // Language layout
        
        Text {
            id: languageLayout
            text: "??"
            color: Theme.accent
            font.family: "Hack"
            font.weight: Font.Bold
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter

            Process {
                command: ["bash", "-c", "hyprctl devices -j | jq -r '[.keyboards[] | select(.main == true)] | .[0].active_keymap'"]
                running: true
                stdout: SplitParser {
                    onRead: data => languageLayout.text = data.trim().substring(0, 2).toUpperCase()
                }
            }

            Connections {
                target: Hyprland
                function onRawEvent(event) {
                    if (event.name === "activelayout")
                        languageLayout.text = event.data.split(",")[1].substring(0, 2).toUpperCase()
                }
            }
        }

        InfoSlider {}

        // Right margin

        Item {
            width: (parent.spacing - 8) * -1
            height: width
        }

        Component.onCompleted: {
            Monitors.updateTemp()
        }
    }
}