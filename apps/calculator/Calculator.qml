import Quickshell
import Quickshell.Io
import QtQuick
import "../../Theme"

// The calculator app: a small fixed-size floating window, opened from anywhere through IPC:
//      > qs ipc call calculator toggle | open | close
// The desktop entry: ~/.local/share/applications/quickshell-calculator.desktop
// The window only exists while it's open.

Scope {
    id: root
    property bool shown: false

    LazyLoader {
        active: root.shown

        FloatingWindow {
            id: win
            visible: true
            title: "Calculator"
            implicitWidth: 320
            implicitHeight: 560
            minimumSize: Qt.size(320, 560)
            maximumSize: Qt.size(320, 560)
            color: Theme.background1
            onClosed: root.shown = false

            CalcContent { anchors.fill: parent }
        }
    }

    IpcHandler {
        target: "calculator"
        function toggle(): void { root.shown = !root.shown }
        function open(): void { root.shown = true }
        function close(): void { root.shown = false }
    }
}
