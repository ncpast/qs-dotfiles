import Quickshell.Services.UPower
import Quickshell
import QtQuick
import "../Theme" 
import "../Utils"

Rectangle {
    readonly property int rad: Theme.concave_radius 

    x:       Theme.left_panel_width - rad
    y:       Theme.top_panel_height - rad
    color:   Theme.background
    width:   285
    height:  65
    radius:  rad
    visible: PopupStates.temp_is_active
    //opacity: 0.9

    Item {
        x: 2 * rad
        y: rad
        width:          parent.width - rad
        height:         parent.height - rad
        anchors.bottom: parent.bottom

        Column {
            visible: PopupStates.temp_displaying == "thermals"
            spacing: 4
            Row {
                spacing: 10
                Text {
                    color: Theme.border
                    text: "CPU temperature:"
                    font.family: "Hack"
                    font.weight: Font.Bold
                    font.pixelSize: 14
                }

                Text {
                    color: Theme.text
                    text: `${Monitors.cpu_temp}°C`
                    font.family: "Hack"
                    font.weight: Font.Bold
                    font.pixelSize: 14
                }
            }

            Row {
                spacing: 10
                Text {
                    color: Theme.border
                    text: "GPU temperature:"
                    font.family: "Hack"
                    font.weight: Font.Bold
                    font.pixelSize: 14
                }

                Text {
                    color: Theme.text
                    text: `${Monitors.gpu_temp}°C`
                    font.family: "Hack"
                    font.weight: Font.Bold
                    font.pixelSize: 14
                }
            }
        }

        Column {
            visible: PopupStates.temp_displaying == "battery"
            spacing: 4
            Row {
                spacing: 10
                Text {
                    color: Theme.border
                    text: "Battery:"
                    font.family: "Hack"
                    font.weight: Font.Bold
                    font.pixelSize: 14
                }

                Text {
                    color: UPower.displayDevice.percentage >= 0.9 ? "#51b34a" : Qt.rgba(
                        (1 - UPower.displayDevice.percentage / 0.9),
                        (180 / 255) * (UPower.displayDevice.percentage / 0.9),
                        0, 1
                    )
                    text: `${Math.round(UPower.displayDevice.percentage * 100)}%` 
                    + (UPower.onBattery ? "" : " Charging ")
                    font.family: "Hack"
                    font.weight: Font.Bold
                    font.pixelSize: 14
                }
            }

            Row {
                spacing: 10
                Text {
                    color: Theme.border
                    text: "Power profile:"
                    font.family: "Hack"
                    font.weight: Font.Bold
                    font.pixelSize: 14
                }

                Text {
                    color: Theme.text
                    text: PopupStates.power_profile
                    font.family: "Hack"
                    font.weight: Font.Bold
                    font.pixelSize: 14
                }
            }
        }
    }

    property color curveColor: Theme.background

    Rectangle {
        rotation: 180
        x: parent.width
        y: rad - 0.01
        width: rad
        height: rad
        color: "transparent"
        clip: true


        Canvas {
            anchors.fill: parent
            smooth: true
            antialiasing: true
            renderTarget: Canvas.FramebufferObject
            renderStrategy: Canvas.Cooperative

            transform: Rotation {
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

    Rectangle {
        rotation: 180
        x: rad
        y: parent.height - 0.01
        width: rad
        height: rad
        color: "transparent"
        clip: true

        Canvas {
            anchors.fill: parent
            smooth: true
            antialiasing: true
            renderTarget: Canvas.FramebufferObject
            renderStrategy: Canvas.Cooperative

            transform: Rotation {
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

    Behavior on height {
        NumberAnimation {
            duration: 300
            easing.type: Easing.InOutQuad
        }
    }
}