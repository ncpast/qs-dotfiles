import Quickshell
import QtQuick
import "../Theme" 

PanelWindow {
    id: topBar
    color: Theme.background

    implicitHeight: 8
    implicitWidth: 8

    Text {
        anchors.centerIn: parent
        color: Theme.text
    }
}