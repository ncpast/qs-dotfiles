import Quickshell
import QtQuick

// Invisible spacer: only reserves screen space (exclusive zone). Takes no input (empty mask): it
// shares the Top layer with the real bars, and if it happens to appear after one of them it sits on
// top of it and would swallow its clicks.
PanelWindow {
    id: topBar
    color: "transparent"
    mask: Region {}

    implicitHeight: 8
    implicitWidth: 8
}
