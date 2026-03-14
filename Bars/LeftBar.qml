import Quickshell
import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import Quickshell.Wayland
import "../Theme"
import "../Widgets"
import Quickshell.Hyprland

PanelWindow {
    id: leftBar
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top;
    
    property string currentTime: ""
    property string currentDate: ""

    anchors {
        left: true
        top: true
        bottom: true
    }

    implicitWidth: 54

    // Top 

    Column {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            bottomMargin: 8
        }
        spacing: Theme.widget_spacing

        Workspaces {
            
        }   
    }

    // Bottom
    
    
    Column {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 8
        }
        spacing: Theme.widget_spacing

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
                const now = new Date();
                let mm = String(now.getMinutes()).padStart(2, '0');
                let hh = String(now.getHours()).padStart(2, '0');
                let datetime = `${String(now.getDate()).padStart(2, '0')}/${String(now.getMonth() + 1).padStart(2, '0')}`;
                currentTime = hh + "\n" + mm;
                currentDate = datetime
            }
        }

        // System tray

        Column {
            spacing: 15
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
                model: SystemTray.items

                TrayItem {
                    opacity: 1
                }
                /*
                Component.onCompleted: {
                    console.log("count:", SystemTray.items.values.length)
                    for (let i = 0; i < SystemTray.items.values.length; i++) {
                        const item = SystemTray.items.values[i]
                        console.log("item", i, "id:", item.id, "title:", item.title, "icon:", item.icon)
                    }
                }
                */
            }

            Rectangle {
                color: "transparent"
                height: -6 // Bottom Margin
                width: height
            }
        }

        Column {
            spacing: 10
            Item {
                width: 40
                height: 40

                Text {
                    color: Theme.border
                    anchors.centerIn: parent
                    text: currentTime
                    font.family: "Hack"
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 18
                }
            }

            Item {
                width: 40
                height: 10

                Text {
                    color: Theme.border
                    anchors.centerIn: parent
                    text: currentDate
                    font.family: "Hack"
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 10
                }
            }
        }


        MediaPlayer {}
        Status {}
        PowerButton {}
    }
}