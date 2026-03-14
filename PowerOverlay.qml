import Quickshell
import QtQuick
import Quickshell.Wayland

PanelWindow {
    id: overlay
    color: "transparent"
    visible: false

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "qs_overlay"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.5
    }

    Timer {
        id: hideTimer
        interval: 3000
        onTriggered: overlay.visible = false
    }

    function show() {
        overlay.visible = true
        hideTimer.restart()
    }
}