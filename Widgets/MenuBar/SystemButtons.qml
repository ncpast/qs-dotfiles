import Quickshell
import QtQuick
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../Theme"
import "../../Utils"

Row {
    id: root
    spacing: 5
    anchors.verticalCenter: parent.verticalCenter

    property bool systemMenuOpen: false
    property string menuOpen: ""
    property var systemAnchorItem: null
    property real popupX: 0
    property real popupY: 0
    property real buttonWidth: 0

    property var systemMenuItems: ({
        "Terminal": {
            label: "Terminal",
            icon: "",
            type: "command",
            action: ["sh", "-c", "cd ~ && kitty"],
            shortcutDispatcher: "exec",
            shortcutArgsContains: "kitty"
        },
        "File Explorer": {
            label: "File Explorer",
            icon: "",
            type: "command",
            action: ["sh", "-c", "cd ~ && thunar"],
            shortcutDispatcher: "exec",
            shortcutArgsContains: "thunar"
        },
        "Preferences": {
            label: "Preferences",
            icon: "",
            type: "command",
            action: ["nwg-look"]
        },
        "Sleep": {
            label: "Sleep",
            icon: "󰤄",
            type: "command",
            action: ["/home/siro/.config/hypr/scripts/suspend.sh"]
        },
        "Lock Screen": {
            label: "Lock Screen",
            icon: "",
            type: "command",
            action: ["hyprlock"],
        },
        "Log Out": {
            label: "Log Out",
            icon: " ",
            type: "command",
            action: ["?"]
        },
        "Shut Down": {
            label: "Shut Down",
            icon: "",
            type: "command",
            action: ["systemctl", "poweroff"]
        },
        "Reboot": {
            label: "Reboot",
            icon: "",
            type: "command",
            action: ["systemctl", "reboot"]
        },
        "Power Saver Profile": {
            label: "Power Saver",
            type: "toggle",
            action: ["systemctl", "reboot"]
        },
        "New Workspace": {
            label: "New",
            type: "command",
            action: ["hyprctl", "dispatch", "workspace", "empty"]
        },
        "Previous Workspace": {
            label: "Previous",
            type: "command",
            action: ["hyprctl", "dispatch", "workspace", "-1"],
            shortcutDispatcher: "workspace",
            shortcutArgsContains: "e-1"
        },
        "Next Workspace": {
            label: "Next",
            type: "command",
            action: ["hyprctl", "dispatch", "workspace", "+1"],
            shortcutDispatcher: "workspace",
            shortcutArgsContains: "e+1"
        },
        "Tiled Workspace": {
            label: "Tile All",
            icon: "󰕮",
            type: "command",
            action: ["./scripts/tileAll.sh"]
        },
        "Floating Workspace": {
            label: "Float All",
            icon: "",
            type: "command",
            action: ["./scripts/floatAll.sh"]
        },
        "Workspace Overview": {
            label: "Overview",
            type: "command",
            action: ["hyprctl", "dispatch", "overview:open"]
        }
    })

    Repeater {
        model: ["System", "Workspace", "View", "Network", "Programs"]

        Rectangle {
            id: delegateRoot
            implicitWidth: label.implicitWidth + 10
            implicitHeight: label.implicitHeight + 8
            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b,
                (mouseArea.containsMouse && !mouseArea.pressed) 
                || (root.systemMenuOpen && root.menuOpen === modelData && !mouseArea.pressed) ? 1 : 0)
            radius: 4

            Behavior on color {
                ColorAnimation { duration: Theme.colorChangeAnimDuration / 2 }
            }

            Text {
                id: label
                anchors.centerIn: parent
                text: modelData
                color: Theme.text
                font.pixelSize: 13
                font.family: "Inter"
                font.weight: modelData === "System" ? Font.Bold : Font.DemiBold
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.menuOpen === modelData) {
                        root.systemMenuOpen = false
                        root.menuOpen = ""
                    } else {
                        root.systemAnchorItem = delegateRoot
                        var pos = delegateRoot.mapToGlobal(0, delegateRoot.height)
                        root.popupX = pos.x
                        root.popupY = pos.y
                        root.buttonWidth = delegateRoot.width
                        root.systemMenuOpen = true
                        root.menuOpen = modelData
                    }
                }
            }
        }
    }

    HyprBinds {
        id: hyprBinds
    }

    Dropdown {
        property var content: ["Terminal", "File Explorer", "Preferences", "br", "Sleep", 
        "Lock Screen", "Log Out", "br", "Shut Down", "Reboot"]
        property var category: "System"
    }

    Dropdown {
        property var content: ["Previous Workspace", "Next Workspace", "New Workspace",
        "br", "Tiled Workspace", "Floating Workspace", "br", "Workspace Overview"]
        property var category: "Workspace"
    }
}