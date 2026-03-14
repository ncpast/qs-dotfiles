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
            /*
            InnerShadow {
                anchors.fill: contentRect
                source: contentRect
                verticalOffset: 0
                horizontalOffset: 0
                radius: 40
                samples: 20
                color: '#000000' // Black with 50% opacity
                spread: 1
                opacity: 0.5
            }
            */
        }

        OpacityMask {
            anchors.fill: parent
            source: outerRect
            maskSource: maskShape
            invert: true
        }
    }

    TemperaturePopup {
        id: temperaturePopup
    }
}