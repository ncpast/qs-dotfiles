import Quickshell
import QtQuick
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import "../../Theme"
import "../../Utils"

Row {
    id: root
    spacing: 5
    anchors.verticalCenter: parent.verticalCenter

    property bool systemMenuOpen: false
    property bool activeWindowFloating: false
    property string menuOpen: ""
    property var systemAnchorItem: null
    property real popupX: 0
    property real popupY: 0
    property real buttonWidth: 0

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
        "Software Center": {
            label: "Software Center",
            icon: "",
            type: "command",
            action: ["plasma-discover"]
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
            action: ["sh", "-c", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"],
            shortcutDispatcher: "exec",
            shortcutArgsContains: "hyprshutdown"
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
            icon: "",
            type: "command",
            action: ["hyprctl", "dispatch", "workspace", "empty"]
        },
        "Previous Workspace": {
            label: "Previous",
            icon: "",
            type: "command",
            action: ["hyprctl", "dispatch", "workspace", "-1"],
            shortcutDispatcher: "workspace",
            shortcutArgsContains: "e-1"
        },
        "Next Workspace": {
            label: "Next",
            type: "command",
            icon: "",
            action: ["hyprctl", "dispatch", "workspace", "+1"],
            shortcutDispatcher: "workspace",
            shortcutArgsContains: "e+1"
        },
        "Tiled Workspace": {
            label: "Tile All",
            icon: "󰕮",
            type: "command",
            action: [Quickshell.env("HOME") + "/.config/quickshell/scripts/tileAll.sh"]
        },
        "Floating Workspace": {
            label: "Float All",
            icon: "",
            type: "command",
            action: [Quickshell.env("HOME") + "/.config/quickshell/scripts/floatAll.sh"]
        },
        "Workspace Overview": {
            label: "Overview",
            icon: "󰕯",
            type: "command",
            action: ["hyprctl", "dispatch", "overview:open"]
        },
        "Maximize": {
            label: "Maximize",
            icon: "",
            type: "command",
            action: ["hyprctl", "dispatch", "fullscreen", "1"],
            shortcutDispatcher: "fullscreen 1"
        },
        "Fullscreen": {
            label: "Fullscreen",
            icon: "",
            type: "command",
            action: ["hyprctl", "dispatch", "fullscreen", "0"],
            shortcutDispatcher: "fullscreen 0"
        },
        "Close Window": {
            label: "Close",
            icon: "󰅙",
            type: "command",
            action: ["hyprctl", "dispatch", "killactive"],
            shortcutDispatcher: "killactive"
        },
        "Move to New Workspace": {
            label: "To New Workspace",
            type: "command",
            action: ["hyprctl", "dispatch", "movetoworkspace", "empty"],
            shortcutDispatcher: "movetoworkspace",
            shortcutArgsContains: "empty"
        },
        "Move to Workspace": {
            label: "Move to Workspace...",
            type: "submenu"
        },
        "Pin Window": {
            label: "Pin",
            type: "command",
            icon: " ",
            action: ["hyprctl", "dispatch", "pin"],
            shortcutDispatcher: "pin",
            requirements: {
                type: "window",
                attribute: "floating"
            }
        },
        "Toggle Floating": {
            label: "Toggle Floating",
            type: "command",
            action: ["hyprctl", "dispatch", "togglefloating"],
            shortcutDispatcher: "togglefloating"
        },
        "Enable Pseudotiling": {
            label: "Pseudotiling",
            type: "command",
            action: ["hyprctl", "dispatch", "pseudo"],
            shortcutDispatcher: "pseudo"
        },
        "Toggle Dock": {
            label: "Dock",
            type: "setter",
            action: () => { console.log('hi') }
        },
        "Compact Mode": {
            label: "Compact Mode",
            type: "setter"
        },
        "Focus Mode": {
            label: "Focus Mode",
            type: "setter"
        },
        "Automatic Tiling": {
            label: "Automatic Tiling",
            type: "setter"
        },
    })

    Repeater {
        model: ["System", "Workspace", "Window", "View", "Network", "Programs"]

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

    HyprlandFocusGrab {
        id: menuGrab
        windows: root.menuOpen === "System" ? [systemDropdown]
            : root.menuOpen === "Workspace" ? [workspaceDropdown]
            : root.menuOpen === "Window" ? [windowDropdown]
            : []
        active: root.systemMenuOpen

        onCleared: {
            root.systemMenuOpen = false
            root.menuOpen = ""
        }
    }

    Dropdown {
        id: systemDropdown
        property var content: ["Terminal", "File Explorer", "Software Center", "Preferences", "br", "Sleep", 
        "Lock Screen", "Log Out", "br", "Shut Down", "Reboot"]
        property var category: "System"
    }

    Dropdown {
        id: workspaceDropdown
        property var content: ["Previous Workspace", "Next Workspace", "New Workspace",
        "br", "Tiled Workspace", "Floating Workspace", "br", "Workspace Overview"]
        property var category: "Workspace"
    }

    Dropdown {
        id: windowDropdown
        property var content: ["Close Window", "Maximize", "Fullscreen", "Pin Window", "br", 
        "Move to Workspace", "Move to New Workspace", "br", "Toggle Floating", "Enable Pseudotiling"]
        property var category: "Window"
    }

    Dropdown {
        id: viewDropdown
        property var content: ["Compact Mode", "Focus Mode", "br", "Toggle Dock", "Automatic Tiling"]
        property var category: "View"
    }
}