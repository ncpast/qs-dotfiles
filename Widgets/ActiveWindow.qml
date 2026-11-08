import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects
import Quickshell.Services.Mpris
import Quickshell.Io
import "../Theme"
import "../Utils"

Item {
    id: root
    width: (hasMedia ? mediaRow.implicitWidth : label.implicitWidth) + 24
    height: parent.height

    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    property bool hasMedia: player !== null && player.trackTitle !== ""
    property bool isPlaying: player !== null && player.isPlaying
    property var cavaBars: [0, 0, 0, 0, 0, 0]
    property string shownMediaText: ""
    property string shownTitle: ""
    property real titleFade: 1

    property string activeTitle: HyprEvents.activeWindowTitle
    property bool showWorkspaces: HyprEvents.currentlySwitchingWorkspaces

    TextMetrics {
        id: mediaMetrics
        font.pixelSize: 13
        font.family: "Inter"
        font.weight: Font.DemiBold
        text: "0".repeat(33)
    }

    property var player: {
        var list = Mpris.players.values
        var fallback = null
        for (var i = 0; i < list.length; i++) {
            var p = list[i]
            if (p.trackTitle === "") continue
            if (p.playbackState === MprisPlaybackState.Playing) return p
            if (fallback === null) fallback = p
        }
        return fallback
    }
    

    property var workspaceIds: {
        var list = Hyprland.workspaces.values
        var ids = []
        for (var i = 0; i < list.length; i++)
            if (list[i].id > 0) ids.push(list[i].id)
        ids.sort((a, b) => a - b)
        return ids
    }

    property string mediaText: {
        if (!hasMedia) return ""
        var t = player.trackArtist !== ""
            ? player.trackArtist + "  •  " + player.trackTitle
            : player.trackTitle
        return t.length > 40 ? t.slice(0, 37) + "..." : t
    }

    onMediaTextChanged: {
        if (mediaText === "") return
        if (shownMediaText === "") shownMediaText = mediaText
        else fadeSwap.restart()
    }

    SequentialAnimation {
        id: fadeSwap
        NumberAnimation { target: media; property: "opacity"; to: 0; duration: 120 }
        ScriptAction { script: root.shownMediaText = root.mediaText }
        NumberAnimation { target: media; property: "opacity"; to: 1; duration: 120 }
    }

    property string titleText: {
        var t = root.activeTitle
        if (t.length === 0) return "Desktop"
        t = t[0].toUpperCase() + t.slice(1)
        return t.length > 50 ? t.slice(0, 47) + "..." : t
    }

    Component.onCompleted: shownTitle = titleText

    onTitleTextChanged: if (!showWorkspaces) titleSwap.restart()

    onShowWorkspacesChanged: {
        if (showWorkspaces) {
            titleSwap.stop()
            titleFade = 1
        } else {
            shownTitle = titleText
        }
    }

    SequentialAnimation {
        id: titleSwap
        NumberAnimation { target: root; property: "titleFade"; to: 0; duration: 120 }
        ScriptAction { script: root.shownTitle = root.titleText }
        NumberAnimation { target: root; property: "titleFade"; to: 1; duration: 120 }
    }

    Process {
        id: cava
        running: root.isPlaying
        command: ["sh", "-c",
            "printf '[general]\\nbars=6\\nframerate=30\\n[output]\\nmethod=raw\\nraw_target=/dev/stdout\\ndata_format=ascii\\nascii_max_range=100\\nbar_delimiter=59\\nframe_delimiter=10\\n' > /tmp/qs-cava.conf && exec cava -p /tmp/qs-cava.conf"
        ]

        stdout: SplitParser {
            onRead: line => {
                var v = line.split(";").map(Number)
                if (v.length >= 6) root.cavaBars = v.slice(0, 6)
            }
        }

        onRunningChanged: if (!running) root.cavaBars = [0, 0, 0, 0, 0, 0]
    }


    Timer {
        id: wsTimer
        interval: 1500
        onTriggered: root.showWorkspaces = false
    }

    DropShadow {
        anchors.fill: activeWindowNameApplet
        radius: Theme.button_shadow_radius
        samples: 17
        color: Theme.button_shadow_color
        source: activeWindowNameApplet
    }

    Rectangle {
        id: activeWindowNameApplet
        color: "transparent"
        radius: 8
        width: parent.width
        height: parent.height - 2

        Item {
            id: titleBox
            anchors.centerIn: parent
            width: label.implicitWidth
            height: label.implicitHeight
            opacity: root.titleFade

            Text {
                id: label
                anchors.centerIn: parent
                text: root.shownTitle
                color: Theme.text
                opacity: (root.hasMedia || root.showWorkspaces) ? 0 : 1
                font.pixelSize: 13
                font.family: "Inter"
                font.weight: Font.DemiBold
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }

        Row {
            id: mediaRow
            anchors.centerIn: parent
            spacing: 10
            opacity: (root.hasMedia && !root.showWorkspaces) ? 1 : 0
            enabled: root.hasMedia && !root.showWorkspaces
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Row {
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: "󰒮"
                    color: Theme.text
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    verticalAlignment: Text.AlignVCenter
                    height: root.height

                    MouseArea {
                        id: prevArea
                        hoverEnabled: true
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.player) root.player.previous()
                    }

                    scale: prevArea.pressed ? 0.85 : (prevArea.containsMouse ? 1.15 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                }

                Text {
                    text: player.isPlaying ? "" : "" 
                    color: Theme.text
                    width: 14
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    height: root.height

                    MouseArea {
                        id: playArea
                        hoverEnabled: true
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.player) root.player.togglePlaying()
                    }
                    
                    scale: playArea.pressed ? 0.85 : (playArea.containsMouse ? 1.15 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                }

                Text {
                    text: "󰒭"
                    color: Theme.text
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    verticalAlignment: Text.AlignVCenter
                    height: root.height

                    MouseArea {
                        id: nextArea
                        hoverEnabled: true
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.player) root.player.next()
                    }
                    
                    scale: nextArea.pressed ? 0.85 : (nextArea.containsMouse ? 1.15 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                id: media
                anchors.verticalCenter: parent.verticalCenter
                width: mediaMetrics.width
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                text: root.shownMediaText
                color: Theme.text
                font.pixelSize: 13
                font.family: "Inter"
                font.weight: Font.DemiBold
            }

            Row {
                id: eq
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: 6
                    Item {
                        width: 3
                        height: 16
                        Rectangle {
                            width: parent.width
                            height: Math.max(2, (root.cavaBars[index] / 100) * 16)
                            anchors.bottom: parent.bottom
                            radius: 1
                            color: Theme.text
                            Behavior on height { NumberAnimation { duration: 60 } }
                        }
                    }
                }
            }
        }

        Row {
            id: dots
            anchors.centerIn: parent
            spacing: 8
            opacity: root.showWorkspaces ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Repeater {
                model: root.workspaceIds

                Rectangle {
                    property bool current: Hyprland.focusedWorkspace !== null
                                        && Hyprland.focusedWorkspace.id === modelData
                    width: 8
                    height: 8
                    radius: 4
                    color: Theme.text
                    opacity: current ? 1.0 : 0.3
                    scale: current ? 1.25 : 1.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                }
            }
        }
    }
}