import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import QtQuick.Shapes
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
        anchors.fill: parent

        // Animated geometry of the clear content area (the hole in the background).
        // Not drawn itself; the Shape below binds to it.
        Item {
            id: contentRect
            x: Theme.leftBarHidden ? 0 : Theme.left_panel_width
            y: Theme.top_panel_height
            width: Theme.leftBarHidden ? root.width : root.width - Theme.left_panel_width - Theme.spacer_panel_size
            height: root.height - Theme.top_panel_height - (Theme.leftBarHidden ? 0 : Theme.spacer_panel_size)

            // square inner corners in focus mode, to match the square, gapless windows
            property real radius: Theme.monotone ? 0 : 20
            // with the side bars hidden the bottom corners sit on the screen edge,
            // where the black screen Corners do the rounding
            property real bottomRadius: Theme.leftBarHidden ? 0 : radius

            Behavior on x            { SpringAnimation { spring: Theme.springStiffness; damping: Theme.springDamping; mass: Theme.springMass; epsilon: Theme.springEpsilon } }
            Behavior on y            { SpringAnimation { spring: Theme.springStiffness; damping: Theme.springDamping; mass: Theme.springMass; epsilon: Theme.springEpsilon } }
            Behavior on width        { SpringAnimation { spring: Theme.springStiffness; damping: Theme.springDamping; mass: Theme.springMass; epsilon: Theme.springEpsilon } }
            Behavior on height       { SpringAnimation { spring: Theme.springStiffness; damping: Theme.springDamping; mass: Theme.springMass; epsilon: Theme.springEpsilon } }
            Behavior on bottomRadius { SpringAnimation { spring: Theme.springStiffness; damping: Theme.springDamping; mass: Theme.springMass; epsilon: Theme.springEpsilon } }
        }

        // Background: full-screen rect with the content area cut out (odd-even fill).
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                // opaque in focus mode (Theme.background is black then)
                fillColor: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, Theme.monotone ? 1 : 0.8)
                fillRule: ShapePath.OddEvenFill
                strokeColor: "transparent"
                strokeWidth: 0

                // Oversized so the hole's edges never touch or cross it, even when the
                // spring overshoots past the screen edges (coincident edges glitch the fill).
                PathRectangle { x: -200; y: -200; width: root.width + 400; height: root.height + 400 }
                PathRectangle {
                    x: contentRect.x; y: contentRect.y
                    width: contentRect.width; height: contentRect.height
                    topLeftRadius:     contentRect.radius
                    topRightRadius:    contentRect.radius
                    bottomLeftRadius:  contentRect.bottomRadius
                    bottomRightRadius: contentRect.bottomRadius
                }
            }
        }
    }

    // TemperaturePopup {
    //     id: temperaturePopup
    // }
}