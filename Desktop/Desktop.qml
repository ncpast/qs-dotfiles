import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects
import "../Theme"
import "../Utils"

// Desktop icons: one layer-shell window per monitor on the lowest (Background) layer,
// so they sit under every window. Visible only while that monitor's active workspace
// has no windows.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        // Fills the area left over by the bars' exclusive zones.
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "quickshell-desktop"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        readonly property var workspace: Hyprland.monitorFor(modelData)?.activeWorkspace ?? null
        readonly property bool workspaceEmpty: workspace !== null
                                            && !HyprEvents.workspaceApps[workspace.id]

        // Stay mapped until the fade-out finishes, then drop out of the way entirely.
        visible: content.opacity > 0

        Item {
            id: content
            anchors.fill: parent
            opacity: win.workspaceEmpty ? 1 : 0
            enabled: win.workspaceEmpty
            Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

            readonly property real cellW: width / DesktopIcons.columns
            readonly property real cellH: height / DesktopIcons.rows

            Repeater {
                model: DesktopIcons.items

                Item {
                    id: cell
                    required property var modelData

                    x: modelData.x * content.cellW
                    y: modelData.y * content.cellH
                    width: content.cellW
                    height: content.cellH
                    visible: modelData.x >= 0 && modelData.x < DesktopIcons.columns
                          && modelData.y >= 0 && modelData.y < DesktopIcons.rows

                    Rectangle {
                        id: tile
                        anchors.centerIn: parent
                        width: DesktopIcons.tileWidth
                        height: DesktopIcons.tileHeight
                        radius: Theme.button_radius
                        color: "transparent"

                        Column {
                            anchors.centerIn: parent
                            width: parent.width - 8
                            spacing: 6

                            Image {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: DesktopIcons.iconSize
                                height: DesktopIcons.iconSize
                                sourceSize: Qt.size(DesktopIcons.iconSize * 2, DesktopIcons.iconSize * 2)
                                smooth: true
                                asynchronous: true
                                source: AppIcons.resolve(cell.modelData.icon)

                                // hover: lightened, press: darkened (like iOS)
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    brightness: mouse.pressed ? -0.35 : (mouse.containsMouse ? 0.1 : 0)
                                    Behavior on brightness { NumberAnimation { duration: 100; easing.type: Easing.InOutQuad } }
                                }

                                // hover: grow, press: shrink, release: spring back up
                                scale: mouse.pressed ? 0.9 : (mouse.containsMouse ? 1.1 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                                }
                            }

                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: cell.modelData.name
                                color: Theme.text
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                font.family: "Inter"
                                font.weight: 500
                                style: Text.Outline
                                styleColor: Qt.rgba(0, 0, 0, 0.4)
                            }
                        }

                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Quickshell.execDetached(cell.modelData.command)
                        }
                    }
                }
            }
        }
    }
}
