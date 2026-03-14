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

// in shell.qml
PanelWindow {
    visible: false
    id: controlPanel

    property bool open: false
    function toggle() { open = !open }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "shell:controlpanel"
    exclusionMode: ExclusionMode.Ignore

    Component.onCompleted: {
        toggle()
    }

    anchors { top: true; left: true }

    implicitWidth: open ? 280 : 0
    implicitHeight: 400

    color: "transparent"

    Behavior on width {
        NumberAnimation {
            duration: 300
            easing.type: Easing.InOutQuad
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.background1
        radius: Theme.button_radius
        border.width: Theme.button_border_width
        border.color: Theme.border

        Column {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 16
            }
            spacing: 12

            Text {
                text: "Control Panel"
                color: Theme.text
                font.pixelSize: 16
                font.weight: Font.Bold
                font.family: "Hack"
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.border
            }

            // dummy elements
            Rectangle {
                width: parent.width
                height: 40
                radius: Theme.button_radius
                color: Theme.background2
                Text {
                    anchors.centerIn: parent
                    text: "Dummy Button 1"
                    color: Theme.text
                    font.family: "Hack"
                }
            }

            Rectangle {
                width: parent.width
                height: 40
                radius: Theme.button_radius
                color: Theme.background2
                Text {
                    anchors.centerIn: parent
                    text: "Dummy Button 2"
                    color: Theme.text
                    font.family: "Hack"
                }
            }

            Rectangle {
                width: parent.width
                height: 80
                radius: Theme.button_radius
                color: Theme.background2
                Text {
                    anchors.centerIn: parent
                    text: "Dummy Widget"
                    color: Theme.text
                    font.family: "Hack"
                }
            }
        }
    }

    // close when clicking outside
    MouseArea {
        anchors.fill: parent
        onClicked: controlPanel.open = false
        z: -1
    }
}