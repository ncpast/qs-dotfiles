import Quickshell
import QtQuick
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

    Canvas {
        anchors.fill: parent
        smooth: true
        antialiasing: true
        renderTarget: Canvas.FramebufferObject
        renderStrategy: Canvas.Cooperative

        transform: Rotation {
            angle: cornerRotation
            origin.x: width / 2
            origin.y: height / 2
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.fillStyle = curveColor
            ctx.beginPath()
            ctx.moveTo(width, 0)
            ctx.lineTo(width, height)
            ctx.lineTo(0, height)
            ctx.arc(0, 0, width, Math.PI * 0.5, 0, true)
            ctx.closePath()
            ctx.fill()
        }
    }
}