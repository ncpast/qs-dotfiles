import QtQuick
import Qt5Compat.GraphicalEffects
import "../Theme"
import "../Utils"

Item {
    implicitWidth: 40
    implicitHeight: column.implicitHeight + 15

    DropShadow {
        anchors.fill: statusBar
        radius: Theme.button_shadow_radius
        samples: 17
        color: Theme.button_shadow_color
        source: statusBar
    }

    Rectangle {
        id: statusBar
        color: Theme.background1
        radius: Theme.button_radius
        border.width: Theme.button_border_width
        border.color: Theme.border

        implicitWidth: 40
        implicitHeight: column.implicitHeight + 15

        /*
        \uf1eb   wifi (generic / full)
        󰤟  wifi strength 1
        󰤢  wifi strength 2
        󰤥  wifi strength 3
        󰤨  wifi strength 4
        󰤭  wifi off

        󰈀  ethernet / wired

        󰂯   bluetooth on
        󰂲  bluetooth off

          volume off (muted)
          volume low
          volume high
          muted
        */
        
        // Load modules

        Component.onCompleted: {
            Audio.updateAudioState()
        }

        Column {
            id: column
            spacing: 10
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            } 

            StatusButton { id: "wifiButton"; icon: "󰈀"; name: "wifi" }
            StatusButton { icon: "󰂲"; name: "bluetooth" }
            StatusButton { 
                icon: Audio.icon; 
                name: "volume"; 
                onClicked: Audio.toggleMute(); 
                id: "volumeStatusBarButton";
                height: 50
            }
        }
    }
}