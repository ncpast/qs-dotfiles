import Quickshell
import QtQuick
import Quickshell.Services.UPower
import QtQuick.Controls
import Quickshell.Io
import "../Utils"
import "../Theme"
import "../Popups"

Row {
    height: parent.height
    anchors.verticalCenter: parent.verticalCenter
    spacing: 4

    property int iconSizeOffset: 0
    property string name: ""
    property string icon: ""
    property var stats: {
    if (name.includes('pu')) {
            const temp = Monitors[name + '_temp']
            return { val: temp, display: temp, col: Theme.accent }
        }
        if (name == 'battery') {
            const pct = UPower.displayDevice.percentage
            const col = pct >= 0.9 ? "#51b34a" : Qt.rgba(
                (1 - pct / 0.9),
                (180 / 255) * (pct / 0.9),
                0, 1
            )
            const bat_ico = () => {
                const icons = [
                    ['󰁺', '󰢜'],  // 0-10%
                    ['󰁻', '󰂆'],  // 10-20%
                    ['󰁼', '󰂇'],  // 20-30%
                    ['󰁽', '󰂈'],  // 30-40%
                    ['󰁾', '󰢝'],  // 40-50%
                    ['󰁿', '󰂉'],  // 50-60%
                    ['󰂀', '󰢞'],  // 60-70%
                    ['󰂁', '󰂊'],  // 70-80%
                    ['󰂂', '󰂋'],  // 80-90%
                    ['󰁹', '󰂄'],  // 90-100%
                ]
                const i = Math.min(Math.floor(pct * 10), 9)
                return icons[i][UPower.onBattery ? 0 : 1]
            }

            return { val: pct, display: bat_ico(), col: col }
        }
        return { val: 0, display: '?', col: Theme.accent }
    }

    property real   val:     stats.val
    property string display: parent.height >= 28 ? stats.display : ""
    property color col:      stats.col

    Item {
        height: parent.height
        width: height

        Text {
            text: display
            anchors.centerIn: parent
            font.weight: Font.Black
            color: col
            font.pixelSize: name.includes('pu') ? parent.height - 21 : parent.height - 18
        }

        Item {
            id: root
            property real progress: name.includes('pu') ? Math.pow(val / 90, 2) : val
            property real animatedProgress: 0
            property int  size:     parent.height
            property int  thickness: 3
            property color trackColor:    Qt.lighter(Theme.background1, Theme.bg_lighter)
            property color progressColor: col

            width: size
            height: size
            anchors.centerIn: parent
            
            MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                propagateComposedEvents: false
                onEntered: {
                    PopupStates.tempEntered()
                    switch  (name) {
                        case "gpu":
                        case "cpu":
                            PopupStates.temp_displaying = "thermals"
                            break;
                        case "battery":
                            StatusUtils.getPowerProfile()
                            PopupStates.temp_displaying = "battery"
                            break;
                    }
                }
                onExited: PopupStates.tempExited()
            }

            Behavior on animatedProgress {
                NumberAnimation {
                    duration: 600
                    easing.type: Easing.InOutQuad
                }
            }

            onProgressChanged: animatedProgress = progress

            Canvas {
                id: canvas
                anchors.fill: parent
                antialiasing: true

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    var cx = width / 2
                    var cy = height / 2
                    var r  = (width / 2) - root.thickness

                    var startAngle = -Math.PI / 2
                    var endAngle   = startAngle + (Math.PI * 2 * root.animatedProgress)

                    ctx.beginPath()
                    ctx.arc(cx, cy, r, 0, Math.PI * 2)
                    ctx.strokeStyle = root.trackColor
                    ctx.lineWidth   = root.thickness
                    ctx.stroke()

                    if (root.animatedProgress > 0) {
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, startAngle, endAngle)
                        ctx.strokeStyle = root.progressColor
                        ctx.lineWidth   = root.thickness
                        ctx.lineCap     = "round"
                        ctx.stroke()
                    }
                }

                onWidthChanged:  requestPaint()
                onHeightChanged: requestPaint()
            }

            onAnimatedProgressChanged: canvas.requestPaint()
        }

    }

    Text {
        visible: icon == "" ? false : (name == "battery" && !UPower.onBattery ? true : false)
        height: parent.height
        text: icon
        //anchors.centerIn: parent
        horizontalAlignment: Text.AlignHLeft
        verticalAlignment: Text.AlignVCenter
        font.weight: Font.Black
        color: col
        font.pixelSize: parent.height - 10 - iconSizeOffset
    }
}