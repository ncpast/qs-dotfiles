import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
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

            // The wallpaper as awww shows it (screen-sized, centre-cropped), placed at its on-screen
            // position relative to this window. Only a texture source for the icons' glass.
            // Loaded at half resolution: it only ever gets blurred.
            Image {
                id: wallImg
                x: -win.margins.left
                y: -win.margins.top
                width: win.modelData.width
                height: win.modelData.height
                source: Theme.tintDesktopIcons ? Wallpaper.urlFor(win.modelData.name) : ""
                sourceSize: Qt.size(width / 2, height / 2)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }

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
                            id: iconColumn
                            anchors.centerIn: parent
                            width: parent.width - 8
                            spacing: 6

                            Item {
                                id: iconItem
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: DesktopIcons.iconSize
                                height: DesktopIcons.iconSize
                                readonly property url src: AppIcons.resolve(cell.modelData.icon)
                                readonly property bool tinted: Theme.tintDesktopIcons

                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    brightness: mouse.pressed ? (Theme.tintDesktopIcons ? -0.1 : -0.35) : (mouse.containsMouse ? 0.1 : 0)
                                    Behavior on brightness { NumberAnimation { duration: 100; easing.type: Easing.InOutQuad } }
                                    shadowEnabled: true
                                    shadowColor: Theme.shadow_color
                                    shadowBlur: Theme.shadow_blur
                                    blurMax: Theme.shadow_blur_max
                                    shadowVerticalOffset: Theme.shadow_offset
                                }

                                // hover: grow, press: shrink, release: spring back up
                                scale: mouse.pressed ? 0.95 : (mouse.containsMouse ? 1.05 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                // Glass (tinted mode only): the wallpaper right behind the icon, blurred and
                                // cut out in the icon's own shape
                                Item {
                                    id: glass
                                    anchors.fill: parent
                                    visible: iconItem.tinted && wallImg.status === Image.Ready

                                    // Blurring only the patch right under the icon averages it into one flat
                                    // colour at strong blur (nothing around it to blend in). So a larger
                                    // patch, padded by the blur radius on every side, is blurred, and only
                                    // the middle (the part under the icon) is used.
                                    readonly property real pad: Math.ceil(glassBlur.blurMax * glassBlur.blur)

                                    ShaderEffectSource {
                                        id: glassSource
                                        x: -glass.pad
                                        y: -glass.pad
                                        width: glass.width + 2 * glass.pad
                                        height: glass.height + 2 * glass.pad
                                        sourceItem: wallImg
                                        visible: false
                                        // the padded patch of wallpaper under the icon. mapToItem isn't
                                        // reactive, so every position on the way up is listed (the icon is
                                        // laid out inside the tile / column after this first runs), plus the
                                        // hover scale and the window position (bars shown / hidden)
                                        sourceRect: {
                                            var deps = iconItem.scale + iconItem.x + iconItem.y
                                                     + iconColumn.x + iconColumn.y + tile.x + tile.y
                                                     + cell.x + cell.y + win.margins.left + win.margins.top
                                                     + wallImg.x + wallImg.y + wallImg.width + wallImg.height
                                            var a = glass.mapToItem(wallImg, -glass.pad, -glass.pad)
                                            var b = glass.mapToItem(wallImg, glass.width + glass.pad, glass.height + glass.pad)
                                            return Qt.rect(a.x, a.y, b.x - a.x, b.y - a.y)
                                        }
                                    }

                                    MultiEffect {
                                        id: glassBlur
                                        anchors.fill: glassSource
                                        source: glassSource
                                        autoPaddingEnabled: false
                                        blurEnabled: true
                                        blurMax: 32
                                        blur: Theme.desktop_icon_glass_blur
                                        visible: false
                                    }

                                    // ...and only the part in the icon's shape is shown: the mask is the
                                    // same padded size, with the icon in the middle
                                    Item {
                                        id: glassShape
                                        anchors.fill: glassSource
                                        visible: false
                                        Image {
                                            x: glass.pad
                                            y: glass.pad
                                            width: glass.width
                                            height: glass.height
                                            source: iconItem.src
                                            sourceSize: Qt.size(DesktopIcons.iconSize * 2, DesktopIcons.iconSize * 2)
                                            asynchronous: true
                                        }
                                    }

                                    OpacityMask {
                                        anchors.fill: glassSource
                                        source: glassBlur
                                        maskSource: glassShape
                                    }

                                    // frosting on top of the blur: how strongly the glass blocks the wallpaper
                                    Rectangle {
                                        id: glassFrost
                                        anchors.fill: glassSource
                                        color: Theme.background
                                        visible: false
                                    }

                                    OpacityMask {
                                        anchors.fill: glassSource
                                        source: glassFrost
                                        maskSource: glassShape
                                        opacity: Theme.desktop_icon_glass_opacity
                                        visible: opacity > 0
                                    }
                                }

                                // The icon itself. Normal mode: as is. Tinted mode: only the texture for
                                // the shader below.
                                Image {
                                    id: iconImg
                                    anchors.fill: parent
                                    sourceSize: Qt.size(DesktopIcons.iconSize * 2, DesktopIcons.iconSize * 2)
                                    smooth: true
                                    asynchronous: true
                                    source: iconItem.src
                                    visible: !iconItem.tinted
                                }

                                // Tinted mode (iOS style): a dark translucent accent tile with a bright
                                // accent glyph, gradients and a sheen on top (shaders/tinted_icon.frag)
                                ShaderEffect {
                                    anchors.fill: parent
                                    visible: iconItem.tinted && iconImg.status === Image.Ready
                                    opacity: Theme.desktop_icon_tint_opacity
                                    property variant source: iconImg
                                    property color tint: Theme.accent
                                    property real tileOpacity: Theme.desktop_icon_tile_opacity
                                    property real gloss: Theme.desktop_icon_gloss
                                    property real glyphScale: cell.modelData.glyphScale ?? 1
                                    fragmentShader: Qt.resolvedUrl("shaders/tinted_icon.frag.qsb")
                                }

                                // Glass rim (tinted mode only)
                                Item {
                                    anchors.fill: parent
                                    visible: iconItem.tinted

                                    Rectangle {
                                        id: rimLight
                                        anchors.fill: parent
                                        visible: false
                                        gradient: Gradient {
                                            GradientStop { position: 0.0;  color: Qt.rgba(1, 1, 1, Theme.desktop_icon_rim_opacity) }
                                            GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, Theme.desktop_icon_rim_opacity * 0.15) }
                                            GradientStop { position: 1.0;  color: Qt.rgba(1, 1, 1, Theme.desktop_icon_rim_opacity * 0.4) }
                                        }
                                    }

                                    Image {
                                        id: rimOuter
                                        anchors.fill: parent
                                        source: iconItem.src
                                        sourceSize: Qt.size(DesktopIcons.iconSize * 2, DesktopIcons.iconSize * 2)
                                        asynchronous: true
                                        visible: false
                                    }

                                    // the shape, inset by the rim width on every side
                                    Item {
                                        id: rimInner
                                        anchors.fill: parent
                                        visible: false
                                        Image {
                                            anchors.centerIn: parent
                                            width: parent.width - 2 * Theme.desktop_icon_rim_width
                                            height: parent.height - 2 * Theme.desktop_icon_rim_width
                                            source: iconItem.src
                                            sourceSize: Qt.size(DesktopIcons.iconSize * 2, DesktopIcons.iconSize * 2)
                                            asynchronous: true
                                        }
                                    }

                                    OpacityMask {
                                        id: rimFilled
                                        anchors.fill: parent
                                        source: rimLight
                                        maskSource: rimOuter
                                        visible: false
                                    }

                                    OpacityMask {
                                        anchors.fill: parent
                                        source: rimFilled
                                        maskSource: rimInner
                                        invert: true
                                    }
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

                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    shadowEnabled: true
                                    shadowColor: Theme.text_shadow_color
                                    shadowBlur: Theme.text_shadow_blur
                                    blurMax: Theme.text_shadow_blur_max
                                    shadowVerticalOffset: Theme.text_shadow_offset
                                }
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
