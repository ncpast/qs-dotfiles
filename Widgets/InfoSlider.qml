import QtQuick
import Qt5Compat.GraphicalEffects
import "../Theme"
import "../Utils"

Rectangle {
    property int length: 200
    height: parent.height - 15
    color: Qt.lighter(Theme.background1, Theme.bg_lighter)
    width: length
    radius: 99
    anchors.verticalCenter: parent.verticalCenter
    
    readonly property int margin_left: 8
    readonly property int margin: 10

    Row {
        width:  parent.width
        height: parent.height
        anchors.right: parent.right
        spacing: 12

        Item {
            id: spacer
            width: (parent.spacing - margin_left + 2) * -1
            height: 1
        }

        Text {
            id: volumeIcon
            height: parent.height
            width: 6
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: Audio.icon
            color: Theme.accent
            font.pixelSize: 12
        }

        Rectangle {
            radius: 99
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.accent
            height: parent.height - margin
            width: (parent.width - margin_left - volumeIcon.width - parent.spacing - margin / 2) * Audio.volume / 100

            Behavior on width {
                NumberAnimation {
                    duration: Theme.colorChangeAnimDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
}