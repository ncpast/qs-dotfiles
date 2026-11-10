import Quickshell.Wayland
import QtQuick

// The real (compositor-enforced) lock surface, one per screen.
WlSessionLockSurface {
    id: lockSurface
    required property var lockRoot

    color: "black"

    LockContent {
        anchors.fill: parent
        lockRoot: lockSurface.lockRoot
        interactive: true
    }
}
