import Quickshell
import QtQuick
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../Theme"
import "../../Utils"

PanelWindow {
        id: systemPopup
        visible: root.systemMenuOpen && root.systemAnchorItem !== null && root.menuOpen === category

        anchors.top: true
        anchors.left: true

        implicitWidth: 200
        implicitHeight: menuColumn.implicitHeight //+ (Theme.button_radius * 2)

        margins.top: -1
        margins.left: popupX - Theme.left_panel_width

        color: "transparent"

        Rectangle {
            id: buttonWrapper
            opacity: root.systemMenuOpen && root.systemAnchorItem !== null ? 1 : 0
            anchors.fill: parent
            color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.8)
            radius: Theme.button_radius
            //border.color: Theme.border
            //border.width: 1

            Column {
                id: menuColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                //anchors.topMargin: Theme.button_radius
                //anchors.bottomMargin: Theme.button_radius
                spacing: 2

                Repeater {
                    model: content
                    id: systemRepeater

                    Rectangle {
                        property var item: root.systemMenuItems[modelData]

                        id: choiceRoot
                        width: menuColumn.width
                        implicitHeight: modelData != "br" ? choiceLabel.implicitHeight + 10 : 6
                        color: Qt.rgba(1, 1, 1, choiceMouseArea.containsMouse ? 0.1 : 0)

                        topLeftRadius: index == 0 ? Theme.button_radius : 0
                        topRightRadius: index == 0 ? Theme.button_radius : 0
                        bottomLeftRadius: index == systemRepeater.count - 1 ? Theme.button_radius : 0
                        bottomRightRadius: index == systemRepeater.count - 1 ? Theme.button_radius : 0

                        Behavior on color {
                            ColorAnimation { duration: Theme.colorChangeAnimDuration / 2 }
                        }

                        
                        Rectangle {
                            visible: modelData === "br"
                            opacity: 0.4
                            color: Theme.border
                            height: 1
                            width: parent.width - 25
                            anchors.centerIn: parent
                        }

                        RowLayout {
                            visible: modelData != "br"
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: 15
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                text: item ? item.icon : ''
                                font.pixelSize: 10
                                color: Theme.text
                                visible: item.icon != undefined
                                Layout.fillHeight: true
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                font.weight: Font.Medium
                                id: choiceLabel
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                verticalAlignment: Text.AlignVCenter
                                text: item.label
                                color: Theme.text
                                font.pixelSize: 13
                                font.family: "Inter"
                            }

                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.fillHeight: true
                                color: "transparent"

                                Text {
                                    opacity: 0.3
                                    font.weight: Font.Medium
                                    text: {
                                        if (!hyprBinds.loaded) return ""
                                        if (!item || !item.shortcutDispatcher || !item.shortcutArgsContains) return ""
                                        return hyprBinds.shortcutFor(item.shortcutDispatcher, item.shortcutArgsContains)
                                    }
                                    font.pixelSize: 14
                                    color: Theme.text
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                }
                            }
                        }

                        MouseArea {
                            visible: modelData != "br"
                            id: choiceMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (item.type == "command" && item.action)
                                    Quickshell.execDetached(item.action);
                                root.systemMenuOpen = false
                                root.menuOpen = ""
                            }
                        }
                    }
                }
            }
        }
    }