import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects
import "../Theme"

Item {
    width: label.implicitWidth + 24
    height: parent.height //label.implicitHeight + 12

    DropShadow {
        anchors.fill: activeWindowNameApplet
        radius: Theme.button_shadow_radius
        samples: 17
        color: Theme.button_shadow_color
        source: activeWindowNameApplet
    }

    Rectangle {
        id: activeWindowNameApplet
        color: "transparent" //Theme.background1
        radius: 8
        width: label.implicitWidth + 24
        height: parent.height - 2 //label.implicitHeight + 10  //+ Theme.active_window_name_offset
        //border.width: .5
        //border.color: Theme.border_light

        Text {
            id: label
            Layout.maximumWidth: 1
            anchors.centerIn: parent
            //anchors.verticalCenterOffset: Theme.active_window_name_offset / 2
            text: {
                var title = Hyprland.activeToplevel?.title || "Desktop";

                if (title.length === 0)
                    return "";

                title = title[0].toUpperCase() + title.slice(1);

                return title.length > 50
                    ? title.slice(0, 47) + "..."
                    : title;
            }
            color: Theme.text
            font.pixelSize: 13
            font.family: "Inter"
            font.weight: Font.DemiBold
        }
    }
}