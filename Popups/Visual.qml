import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import "../Theme" 
import "../Widgets"
import "../Utils"

PanelWindow {
    WlrLayershell.namespace: "shell:controlpanel"
    WlrLayershell.layer: WlrLayer.Top;
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    mask: Region {}

    Item {
        id: root
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        //visible: false

        Rectangle {
            id: outerRect
            anchors.fill: parent
            //radius: 20
            color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 1)
            visible: false
        }

        Item {
            id: maskShape
            anchors.fill: parent
            visible: false

            Rectangle {
                id: contentRect
                x: Theme.left_panel_width + Theme.spacer_panel_size - Theme.spacer_panel_size
                y: Theme.top_panel_height + Theme.spacer_panel_size - Theme.spacer_panel_size
                width: root.width - Theme.left_panel_width - Theme.spacer_panel_size
                height: root.height - Theme.top_panel_height - Theme.spacer_panel_size
                color: "white"
                radius: 20
            }
        }

        OpacityMask {
            anchors.fill: parent
            source: outerRect
            maskSource: maskShape
            invert: true
        }
    }

    
    /*
    Item {
        id: shadow
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        
        DropShadow {
            visible: false
            id: outerRectShadow

            anchors.fill: maskShapeShadow
            radius: Theme.button_shadow_radius
            samples: 17
            color: "black"
            source: maskShapeShadow
        }

        Item {
            id: maskShapeShadow
            anchors.fill: parent
            //visible: false

            Item {
                id: maskShapeShadow2
                anchors.fill: parent
                visible: false

                Rectangle {
                    id: outerRectShadow2
                    x: Theme.left_panel_width + Theme.spacer_panel_size - Theme.spacer_panel_size
                    y: Theme.top_panel_height + Theme.spacer_panel_size - Theme.spacer_panel_size
                    width: root.width - Theme.left_panel_width - Theme.spacer_panel_size
                    height: root.height - Theme.top_panel_height - Theme.spacer_panel_size
                    color: "black"
                    radius: 20
                }
            }

            OpacityMask {
                anchors.fill: parent
                source: outerRectShadow2
                maskSource: maskShapeShadow2
                invert: true
            }
        }

        OpacityMask {
            anchors.fill: parent
            source: outerRectShadow
            maskSource: maskShapeShadow
            invert: true
        }
    }
    */

    TemperaturePopup {
        id: temperaturePopup
    }
}