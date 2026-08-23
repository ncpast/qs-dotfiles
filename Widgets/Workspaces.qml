import QtQuick
import Quickshell
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects
import "../Theme"

Item {
    id: desktopIndicator
    property int totalDesktops: 1
    property int activeDesktop: Hyprland.activeWorkspace || 0  
    property list<int> urgentDesktops: []
    property var workspaceArray: Hyprland.workspaces.values

    width: 40
    height: totalDesktops * 18  // adjust spacing


    DropShadow {
        anchors.fill: container
        source: container
        radius: Theme.button_shadow_radius
        samples: 17
        color: Theme.button_shadow_color
    }

    Rectangle {
        id: container
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
        }

        implicitWidth: column.implicitWidth + padding * 2
        implicitHeight: column.implicitHeight + padding * 2
        color: Theme.background1
        radius: Theme.button_radius

        property int padding: 10

        Column {
            anchors {
                verticalCenter: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
            }
            spacing: 10
            id: column

            Repeater {
                model: totalDesktops
                Rectangle {
                    width: 10
                    height: index == activeDesktop ? width*2 : width
                    radius: 999
                    color: {
                        if (urgentDesktops.includes(index))
                            return blinkState ? Theme.border_light : Theme.text
                        else if (index == activeDesktop)
                            return Theme.accent
                        else
                            return Theme.border_light
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.animDuration
                            easing.type: Easing.InOutQuad
                        }
                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: Theme.animDuration
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            //console.log("Hyprland event:", event.name);

            if (event.name.includes("workspace") || event.name.includes("urgent")) {
                //console.log("Moved workspace ", event.name);
                totalDesktops = Hyprland.workspaces.values.length > 5 ? Hyprland.workspaces.values.length : 5

                for (let i = 0; i < Hyprland.workspaces.values.length; i++) {
                    if (Hyprland.workspaces.values[i].active) {
                        //console.log(Hyprland.workspaces.values[i])
                        activeDesktop = i;
                        urgentDesktops = urgentDesktops.filter(d => d !== i)
                    }

                    if (Hyprland.workspaces.values[i].urgent && !urgentDesktops.includes(i)) {
                        //console.log(`Added desktop ${i} to urgent`)
                        urgentDesktops = [...urgentDesktops, i]
                    }
                }
            }
        }
    }

    property bool blinkState: false

    Timer {
        id: blinkTimer
        interval: 500
        repeat: true
        running: urgentDesktops.length > 0
        onTriggered: blinkState = !blinkState
    }

    Component.onCompleted: {
        totalDesktops = Hyprland.workspaces.values.length > 5 ? Hyprland.workspaces.values.length : 5

        for (let i = 0; i < Hyprland.workspaces.values.length; i++) {
            if (Hyprland.workspaces.values[i].active) {
                activeDesktop = i;
            }
        }
    }
}