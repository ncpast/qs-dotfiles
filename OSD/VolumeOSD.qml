import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "../Theme"
import "../Utils"

// Note for future self:
// make it recheck fullscreen value when button is pressed
// as well as when a new workspace is entered

Item {
    id: osdController

    property bool wantShown: false
    property bool isFullscreen: false
    // false: showing volume, true: showing brightness (same OSD, different icons/value)
    property bool brightnessMode: false

    // Fullscreen only counts if the *active workspace* has a fullscreen window and that
    // window is the focused one. Asking Hyprland directly avoids two problems of the old
    // check: the stale "active toplevel" left over after switching to an empty workspace,
    // and reading the toplevel before its refresh had finished.
    function updateFullscreenState() {
        if (!fullscreenProc.running) fullscreenProc.running = true
    }

    Process {
        id: fullscreenProc
        command: ["sh", "-c", "jq -n --argjson w \"$(hyprctl -j activeworkspace)\" --argjson a \"$(hyprctl -j activewindow)\" '($w.hasfullscreen == true) and ($a.fullscreen == 2)'"]
        stdout: StdioCollector {
            onStreamFinished: osdController.isFullscreen = text.trim() === "true"
        }
    }

    LazyLoader {
        id: osdLoader
        active: false

        PanelWindow {
            id: panelRoot
            // Only as big as the strip the pill slides through (not full-screen), so each
            // animation frame only damages/recomposites this small area.
            anchors { top: true }
            implicitWidth:       root.implicitWidth
            implicitHeight:      120   // shown margin (<= ~40) + pill (40) + spring overshoot
            WlrLayershell.layer: WlrLayer.Overlay
            exclusionMode:       ExclusionMode.Ignore
            mask:                Region {}
            color:               "transparent"

            Rectangle {
                id: root
                radius:         20
                implicitHeight: 40
                implicitWidth:  400
                color: Qt.rgba(Theme.background1.r, Theme.background1.g, Theme.background1.b, 0.8)

                property real shownMargin:  (isFullscreen ? 5 : Theme.top_panel_height) + 5
                property real hiddenMargin: -implicitHeight - 20

                anchors.top:              parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin:        hiddenMargin   // initial value, not animated

                function applyState() {
                    anchors.topMargin = osdController.wantShown ? shownMargin : hiddenMargin
                }

                Component.onCompleted: {
                    updateFullscreenState()
                    applyState()   // runs after construction -> Behavior animates the slide-in
                }

                // React to the external flag. Purely visual — never touches the loader.
                Connections {
                    target: osdController
                    function onWantShownChanged() { root.applyState() }
                }

                // The fullscreen check is asynchronous: re-apply once its result lands.
                Connections {
                    target: osdController
                    function onIsFullscreenChanged() { root.applyState() }
                }

                Connections {
                    target: Hyprland
                    function onRawEvent(event) {
                        switch (event.name) {
                        case "fullscreen":
                        case "workspace":
                        case "workspacev2":
                        case "focusedmon":
                        case "moveworkspace":
                        case "moveworkspacev2":
                        case "activewindow":
                        case "activewindowv2":
                        default:
                            updateFullscreenState()
                            if (osdController.wantShown) root.applyState()
                            break
                        }
                    }
                }

                Behavior on anchors.topMargin {
                    SpringAnimation {
                        spring:  Theme.springStiffness
                        damping: Theme.springDamping
                        mass:    Theme.springMass
                        epsilon: Theme.springEpsilon
                    }
                }

                Rectangle {
                    height: root.height
                    width: height
                    color: "transparent"
                    anchors.left: root.left

                    Text {
                        text: osdController.brightnessMode ? "󰃞" : Audio.muted ? '' : ''
                        anchors.centerIn: parent
                        font.family: 'JetBrainsMono Nerd Font'
                        font.pixelSize: 16
                        color: Theme.text
                    }
                }

                Rectangle {
                    id: slidercontainer
                    height: root.height
                    width: root.width - root.height * 2
                    anchors.horizontalCenter: root.horizontalCenter
                    color: "transparent"

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: 3
                        width: parent.width
                        spacing: 2

                        Rectangle {
                            height: 6
                            radius: 3
                            width:  parent.width
                            color:  Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)

                            Rectangle {
                                height: parent.height
                                radius: parent.radius
                                width:  osdController.brightnessMode ? parent.width * Brightness.percent / 100
                                       : (Audio.muted ? 0 : parent.width * Audio.volume / 100)
                                color:  Theme.text

                                Behavior on width {
                                    NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            height: 10

                            Repeater {
                                model: 20
                                Item {
                                    width: parent.width / 20
                                    height: parent.height

                                    Rectangle {
                                        width: 3
                                        height: 3
                                        radius: width / 2
                                        color: Theme.text
                                        opacity: 0.2
                                        anchors.centerIn: parent
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    height: root.height
                    width: height
                    color: "transparent"
                    anchors.right: root.right

                    Text {
                        text: osdController.brightnessMode ? "󰃠" : Audio.muted ? '' : ''
                        anchors.centerIn: parent
                        font.family: 'JetBrainsMono Nerd Font'
                        font.pixelSize: 16
                        color: Theme.text
                    }
                }
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 2000
        repeat: false
        onTriggered: osdController.wantShown = false
    }

    Timer {
        id: unloadTimer
        interval: 400
        repeat: false
        onTriggered: {
            if (!osdController.wantShown) osdLoader.active = false
        }
    }

    onWantShownChanged: {
        if (!wantShown) unloadTimer.restart()
        else unloadTimer.stop()
    }

    function show() {
        wantShown = true
        hideTimer.restart()
        osdLoader.active = true
    }

    // Leading-edge throttle: play right away, then ignore changes for a moment so
    // holding the key doesn't spawn a paplay process per step.
    Timer {
        id: soundCooldown
        interval: 50
    }

    function playVolumeSound() {
        if (soundCooldown.running) return
        soundCooldown.start()
        Quickshell.execDetached(["paplay", `/usr/share/sounds/${Theme.sound_theme}/stereo/audio-volume-change.oga`])
    }

    Connections {
        target: Audio
        // the first reading after the shell (re)starts isn't a change: no OSD, no sound
        function onVolumeChanged() {
            if (!Audio.volumeKnown) return
            osdController.brightnessMode = false
            updateFullscreenState()
            osdController.show()
            playVolumeSound()
        }
        function onMutedChanged() {
            if (!Audio.muteKnown) return
            osdController.brightnessMode = false
            osdController.show()
        }
    }

    Connections {
        target: Brightness
        function onAdjusted() {
            osdController.brightnessMode = true
            updateFullscreenState()
            osdController.show()
        }
    }
}