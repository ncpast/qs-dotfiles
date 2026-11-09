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

        // Only as big as the block of grid cells the icons actually occupy. A full-screen
        // transparent surface that fades is expensive for the compositor (it re-composites
        // the whole screen for every frame of the fade), which made workspace switches
        // stutter; this window covers only a fraction of the screen.
        // Grid geometry is computed from the screen minus the bars, so cells are identical to
        // the old full-area layout.
        readonly property real insetTop: Theme.top_panel_height
        readonly property real insetLeft: Theme.leftBarHidden ? 0 : Theme.left_panel_width
        readonly property real insetRight: Theme.leftBarHidden ? 0 : Theme.spacer_panel_size
        readonly property real insetBottom: Theme.leftBarHidden ? 0 : Theme.spacer_panel_size
        readonly property real cellW: (modelData.width - insetLeft - insetRight) / DesktopIcons.columns
        readonly property real cellH: (modelData.height - insetTop - insetBottom) / DesktopIcons.rows

        readonly property var cells: {
            var minX = DesktopIcons.columns, maxX = -1, minY = DesktopIcons.rows, maxY = -1
            for (var i = 0; i < DesktopIcons.items.length; i++) {
                var it = DesktopIcons.items[i]
                if (it.x < 0 || it.x >= DesktopIcons.columns || it.y < 0 || it.y >= DesktopIcons.rows) continue
                minX = Math.min(minX, it.x); maxX = Math.max(maxX, it.x)
                minY = Math.min(minY, it.y); maxY = Math.max(maxY, it.y)
            }
            if (maxX < 0) return { minX: 0, minY: 0, cols: 1, rows: 1 }
            return { minX: minX, minY: minY, cols: maxX - minX + 1, rows: maxY - minY + 1 }
        }

        anchors { top: true; left: true }
        exclusionMode: ExclusionMode.Ignore
        margins.left: insetLeft + cells.minX * cellW
        margins.top: insetTop + cells.minY * cellH
        implicitWidth: cells.cols * cellW
        implicitHeight: cells.rows * cellH
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "quickshell-desktop"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        readonly property var workspace: Hyprland.monitorFor(modelData)?.activeWorkspace ?? null
        readonly property bool workspaceEmpty: workspace !== null
                                            && !HyprEvents.workspaceApps[workspace.id]

        // Stays mapped for good: creating the layer surface (and its scene graph) each time
        // the workspace became empty cost a ~40 ms hitch right as the fade started, which
        // stalled every other animation in the shell. While the icons are hidden the input
        // region is empty, so clicks pass through to whatever is underneath.
        visible: true
        mask: win.workspaceEmpty ? shownRegion : hiddenRegion
        Region { id: shownRegion; item: content }
        Region { id: hiddenRegion }

        // ---- fade logic -------------------------------------------------------------
        // Fading while the workspace slides to/from one with tiled windows made the switch
        // stutter, so for a switch between an empty desktop and a tiled one the icons snap
        // in or out instantly. Every other change - opening an app on this desktop, a
        // workspace that only has floating windows - keeps the normal fade.
        readonly property int wsId: workspace ? workspace.id : -1
        property int settledWsId: wsId          // lags wsId by 50 ms, so "wsId !== settledWsId" means "just switched"
        onWsIdChanged: settleTimer.restart()
        Timer { id: settleTimer; interval: 50; onTriggered: win.settledWsId = win.wsId }

        readonly property real targetOpacity: workspaceEmpty ? 1 : 0

        NumberAnimation {
            id: fade
            target: content
            property: "opacity"
            duration: 400
            easing.type: Easing.OutCubic
        }

        onTargetOpacityChanged: {
            fade.stop()
            // read the workspace directly: the derived wsId property is updated *after* this
            // handler runs, so it would still hold the previous workspace here
            var id = workspace ? workspace.id : -1
            var switched = id !== settledWsId
            var tiledHere = HyprEvents.workspaceTiled[id] === true
            // settledWsId still holds the workspace we just left
            var leftTiled = HyprEvents.workspaceTiled[settledWsId] === true
            if (switched && ((targetOpacity === 0 && tiledHere) || (targetOpacity === 1 && leftTiled))) {
                content.opacity = targetOpacity          // instant, both ways
            } else {
                fade.to = targetOpacity
                fade.start()
            }
        }

        Item {
            id: content
            anchors.fill: parent
            opacity: 0
            enabled: win.workspaceEmpty
            Component.onCompleted: opacity = win.targetOpacity

            readonly property real cellW: win.cellW
            readonly property real cellH: win.cellH

            Repeater {
                model: DesktopIcons.items

                Item {
                    id: cell
                    required property var modelData

                    x: (modelData.x - win.cells.minX) * content.cellW
                    y: (modelData.y - win.cells.minY) * content.cellH
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
