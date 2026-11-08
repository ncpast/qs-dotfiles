import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import "../../Theme"
import "../../Utils"

// "Programs" tab: one row per system tray item (background programs).
// Left click opens the app, right click closes it.
PanelWindow {
    id: programsPopup
    property var category: "Programs"

    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    Shortcut {
        sequence: "Escape"
        enabled: root.systemMenuOpen
        onActivated: {
            root.systemMenuOpen = false
            root.menuOpen = ""
        }
    }

    visible: root.systemMenuOpen && root.systemAnchorItem !== null && root.menuOpen === category

    anchors.top: true
    anchors.left: true

    implicitWidth: 200
    implicitHeight: menuColumn.implicitHeight

    margins.top: -1
    margins.left: popupX - (Theme.leftBarHidden ? 0 : Theme.left_panel_width)

    color: "transparent"

    // Quit a tray app: prefer its own "Quit"/"Exit" menu entry (a graceful quit that
    // works even when the app has no window, e.g. minimised to tray); otherwise ask
    // Hyprland to close a window whose class matches the tray id.
    function closeProgram(item, opener) {
        var entries = opener && opener.children ? opener.children.values : []
        for (var i = 0; i < entries.length; i++) {
            var e = entries[i]
            if (e.isSeparator || !e.enabled) continue
            var label = (e.text || "").replace(/&/g, "")
            if (/^(quit|exit|close)\b|\b(quit|exit)\b/i.test(label)) {
                e.triggered()
                return
            }
        }
        var cls = (item.id || item.title || "").replace(/["\\]/g, "")
        if (cls !== "")
            Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.window.close({ window = \"class:(?i)" + cls + "\" })"])
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.8)
        radius: Theme.button_radius
        opacity: root.systemMenuOpen && root.systemAnchorItem !== null ? 1 : 0

        Column {
            id: menuColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 2

            // Empty state
            Item {
                visible: SystemTray.items.values.length === 0
                width: menuColumn.width
                height: visible ? emptyLabel.implicitHeight + 10 : 0

                Text {
                    id: emptyLabel
                    anchors.left: parent.left
                    anchors.leftMargin: 15
                    anchors.verticalCenter: parent.verticalCenter
                    text: "No background programs."
                    color: Theme.text
                    opacity: 0.45
                    font.pixelSize: 13
                    font.family: "Inter"
                    font.weight: Font.Medium
                }
            }

            Repeater {
                id: programRepeater
                model: SystemTray.items

                Rectangle {
                    id: row
                    required property var modelData
                    required property int index

                    // desktop entry matching this tray item (gives the proper name + icon)
                    readonly property var entry: AppIcons.entryFor(modelData.id) || AppIcons.entryFor(modelData.title)

                    width: menuColumn.width
                    implicitHeight: programLabel.implicitHeight + 10
                    color: Qt.rgba(1, 1, 1, rowMouse.containsMouse ? 0.1 : 0)

                    topLeftRadius: index == 0 ? Theme.button_radius : 0
                    topRightRadius: index == 0 ? Theme.button_radius : 0
                    bottomLeftRadius: index == programRepeater.count - 1 ? Theme.button_radius : 0
                    bottomRightRadius: index == programRepeater.count - 1 ? Theme.button_radius : 0

                    Behavior on color {
                        ColorAnimation { duration: Theme.colorChangeAnimDuration / 2 }
                    }

                    QsMenuOpener {
                        id: menuOpener
                        menu: row.modelData.menu
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 15
                        anchors.rightMargin: 10
                        spacing: 8

                        Image {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            sourceSize: Qt.size(32, 32)
                            smooth: true
                            asynchronous: true
                            // AppIcons first (same icons as the rest of the shell), the tray
                            // item's own icon as a fallback
                            source: AppIcons.lookup(row.entry ? row.entry.id : "")
                                 || AppIcons.lookup(row.modelData.id)
                                 || AppIcons.lookup(row.modelData.title)
                                 || row.modelData.icon
                        }

                        Text {
                            id: programLabel
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            verticalAlignment: Text.AlignVCenter
                            text: AppIcons.displayName(row.modelData.id, row.modelData.title)
                            color: Theme.text
                            elide: Text.ElideRight
                            font.pixelSize: 13
                            font.family: "Inter"
                            font.weight: Font.Medium
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: event => {
                            if (event.button === Qt.LeftButton)
                                row.modelData.activate()
                            else
                                programsPopup.closeProgram(row.modelData, menuOpener)
                            root.systemMenuOpen = false
                            root.menuOpen = ""
                        }
                    }
                }
            }
        }
    }
}
