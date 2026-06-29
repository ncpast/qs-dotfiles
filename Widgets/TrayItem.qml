pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects
import "../Theme"

MouseArea {
    id: root
    required property SystemTrayItem modelData
    property int iconSize: 10 

    implicitWidth: 30
    implicitHeight: 30
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    hoverEnabled: true

    onClicked: event => {
        //console.log(modelData[0])
        if (event.button === Qt.LeftButton)
            modelData.activate()
        else
            modelData.secondaryActivate()
    }

    DropShadow {
        anchors.fill: iconRectangleButton
        radius: Theme.button_shadow_radius
        samples: 17
        color: Theme.button_shadow_color
        source: iconRectangleButton
    }

    Rectangle {
        id: iconRectangleButton
        anchors.centerIn: parent
        radius: Theme.button_radius - 2
        color: root.pressed ? Theme.background1 : root.containsMouse ? Theme.background2 : Theme.background1
        width: root.pressed ? parent.width : root.containsMouse ? parent.width + 2 : parent.width
        height: root.pressed ? parent.height : root.containsMouse ? parent.height + 2 : parent.height

        Behavior on color { ColorAnimation { duration: Theme.colorChangeAnimDuration; easing.type: Easing.InOutQuad } }
        Behavior on width { NumberAnimation { duration: Theme.colorChangeAnimDuration; easing.type: Easing.InOutQuad } }
        Behavior on height { NumberAnimation { duration: Theme.colorChangeAnimDuration; easing.type: Easing.InOutQuad } }

        Item {
            anchors.centerIn: parent
            height: parent.height - iconSize
            width: height
            Rectangle {
                id: blendBase
                anchors.fill: parent
                color: iconRectangleButton.color
                visible: false
            }

            // 2. The icon source (hidden, used only as a graphical input)
            IconImage {
                id: trayIcon
                anchors.fill: parent
                source: modelData.icon
                visible: false 
            }

            // 3. The effect that applies the multiply blending mode
            Blend {
                anchors.fill: parent
                source: blendBase
                foregroundSource: trayIcon
                mode: "lighten"
                opacity: 0.8
            }
        }
    }
}