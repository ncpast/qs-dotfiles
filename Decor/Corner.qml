import Quickshell
import QtQuick
import QtQuick.Shapes
import Quickshell.Wayland
import "../Theme"

PanelWindow {
    id: corner
    color: "transparent"

    property int cornerRotation: 0
    property int radius: 24
    property color curveColor: Theme.background

    implicitWidth: radius
    implicitHeight: radius
    //exclusionMode: ExclusionMode.Ignore

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        transform: Rotation {
            angle: cornerRotation
            origin.x: width / 2
            origin.y: height / 2
        }

        // Square with a quarter circle (centred on the top-left) cut out
        ShapePath {
            fillColor: curveColor
            strokeColor: "transparent"
            strokeWidth: 0

            startX: corner.width; startY: 0
            PathLine { x: corner.width; y: corner.height }
            PathLine { x: 0;            y: corner.height }
            PathArc {
                x: corner.width; y: 0
                radiusX: corner.width; radiusY: corner.height
                direction: PathArc.Counterclockwise
            }
        }
    }
}