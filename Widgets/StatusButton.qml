import QtQuick
import Qt5Compat.GraphicalEffects
import "../Theme"
import "../Utils"

Rectangle {
    property string name: ""
    property string icon: ""
    property bool   active: false
    property string label: ""

    signal clicked()

    width: 30
    height: width
    radius: Theme.button_radius - 3
    color: mouseArea.pressed ? Theme.background1 : mouseArea.containsMouse ? Theme.background2 : Theme.background1
    border.width: Theme.button_border_width
    border.color: mouseArea.pressed ? Theme.border : mouseArea.containsMouse ? Theme.accent : Theme.border

    Behavior on color        { ColorAnimation { duration: 100; easing.type: Easing.InOutQuad } }
    Behavior on border.color { ColorAnimation { duration: 100; easing.type: Easing.InOutQuad } }

    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: name === "volume" ? -8 : 0
        text: parent.icon
        color: mouseArea.pressed ? Theme.border : mouseArea.containsMouse ? Theme.accent : Theme.border
        font.pixelSize: 16
        Behavior on color { ColorAnimation { duration: 100; easing.type: Easing.InOutQuad } }
    }

    Text {
        visible: name === "volume"
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: 3
        }
        text: Audio.volume
        color: mouseArea.pressed ? Theme.border : mouseArea.containsMouse ? Theme.accent : Theme.border
        font.pixelSize: 10
        font.family: 'JetBrainsMono Nerd Font'
        font.weight: Font.Black
        Behavior on color        { ColorAnimation { duration: 100; easing.type: Easing.InOutQuad } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: parent.clicked()
        cursorShape: Qt.PointingHandCursor
    }
}