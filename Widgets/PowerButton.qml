import QtQuick
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import "../Theme"

Item {
    width: 40
    height: 40

    DropShadow {
        anchors.fill: powerBtn
        radius: Theme.button_shadow_radius
        samples: 17
        color: Theme.button_shadow_color
        source: powerBtn
    }

    Rectangle {
        id: powerBtn
        color: mouseArea.pressed ? Theme.background1 : mouseArea.containsMouse ? Theme.background2 : Theme.background1
        radius: Theme.button_radius
        width: 40
        height: 40
        border.width: Theme.button_border_width
        border.color: mouseArea.pressed ? Theme.border : mouseArea.containsMouse ? Theme.accent : Theme.border

        QtObject {
            id: theme
            readonly property int animDuration: 100
        }

        Process {
            id: powerScript
            command: ["bash", "/home/siro/.config/hypr/scripts/wlogout.sh"]
        }

        Behavior on color {
            ColorAnimation {
                duration: theme.animDuration
                easing.type: Easing.InOutQuad
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: theme.animDuration
                easing.type: Easing.InOutQuad
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: powerScript.running = true
            cursorShape: Qt.PointingHandCursor 
        }

        Text {
            anchors.centerIn: parent
            text: "\uf011"
            color: mouseArea.pressed ? Theme.border : mouseArea.containsMouse ? Theme.accent : Theme.border
            font.pixelSize: 18
            font.family: "Inter"

            Behavior on color {
                ColorAnimation {
                    duration: theme.animDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
}