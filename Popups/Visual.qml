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

    // Init monitors: 
    Component.onCompleted: {
        void(PowerProfiles)
    }

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
            color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.8)
            visible: false
        }

        Item {
            id: maskShape
            anchors.fill: parent
            visible: false

            Rectangle {
                id: contentRect
                x: Theme.left_panel_width + Theme.spacer_panel_size - Theme.spacer_panel_size +
                (Theme.leftBarHidden ? -Theme.left_panel_width : 0)
                y: Theme.top_panel_height + Theme.spacer_panel_size - Theme.spacer_panel_size
                width: root.width - Theme.left_panel_width - Theme.spacer_panel_size +
                (Theme.leftBarHidden ? Theme.left_panel_width + Theme.spacer_panel_size : 0)
                height: root.height - Theme.top_panel_height - (Theme.leftBarHidden ? 0 : Theme.spacer_panel_size)
                color: "white"
                radius: 20

                /*
                Behavior on x {
                    SpringAnimation {
                        spring: Theme.springStiffness
                        damping: Theme.springDamping
                        mass: Theme.springMass
                        epsilon: Theme.springEpsilon
                    }
                }
                Behavior on y {
                    SpringAnimation {
                        spring: Theme.springStiffness
                        damping: Theme.springDamping
                        mass: Theme.springMass
                        epsilon: Theme.springEpsilon
                    }
                }
                Behavior on width {
                    SpringAnimation {
                        spring: Theme.springStiffness
                        damping: Theme.springDamping
                        mass: Theme.springMass
                        epsilon: Theme.springEpsilon
                    }
                }
                Behavior on height {
                    SpringAnimation {
                        spring: Theme.springStiffness
                        damping: Theme.springDamping
                        mass: Theme.springMass
                        epsilon: Theme.springEpsilon
                    }
                }
                */
            }
        }

        OpacityMask {
            anchors.fill: parent
            source: outerRect
            maskSource: maskShape
            invert: true
        }
    }

    // TemperaturePopup {
    //     id: temperaturePopup
    // }
}