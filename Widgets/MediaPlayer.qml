import Quickshell
import QtQuick
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects
import "../Theme"

Item {
    implicitWidth: parent.width
    height: 80

    property var player: Mpris.players.values[0] ?? null
    property int playerOffset: 6

    DropShadow {
        anchors.fill: container
        radius: Theme.button_shadow_radius
        samples: 17
        color: Theme.button_shadow_color
        source: container
    }

    Rectangle {
        id: container
        anchors.fill: parent
        color: "black"
        border.width: 1
        border.color: Theme.background1
        radius: Theme.button_radius

        Column {
            width: parent.width
            height: parent.height

            Item {
                width: parent.width 
                height: parent.height - parent.width 

                Rectangle {
                    radius: Theme.button_radius
                    color: "transparent"
                    width: parent.width - playerOffset
                    height: width
                    anchors.centerIn: parent

                    Image {
                        id: albumArt
                        anchors.fill: parent
                        source: player ? player.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        visible: false
                    }

                    Rectangle {
                        id: mask
                        anchors.fill: parent
                        radius: Theme.button_radius
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: albumArt
                        maskSource: mask
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.button_radius
                        color: "transparent"
                        //border.width: 2
                        //border.color: Theme.background1
                    }
                }
            }

            Item {
                width: parent.width
                height: parent.width

                Item {
                    anchors.centerIn: parent
                    width: parent.width - 15
                    height: width

                    Text {
                        Behavior on color { ColorAnimation { duration: 100 } }
                        anchors.centerIn: parent
                        text: player && player.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
                        color: "white"
                        opacity: 0.4
                        font.pixelSize: 20
                        font.family: "JetBrainsMono Nerd Font"

                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: event => {
                            if (!player) return
                            
                            if (event.button == Qt.LeftButton)
                                player.togglePlaying()
                            else if (event.button == Qt.RightButton)
                                player.next()
                        }
                    }
                }
            }
        }
    }
}