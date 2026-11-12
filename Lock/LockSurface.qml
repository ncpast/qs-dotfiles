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

        // pointer movement, for showing the cursor again after a login lock. On LockContent itself:
        // a handler on the parent sees movement over the children without taking their hover (as a
        // separate item on top it did, and the power buttons lost their hover effects).
        HoverHandler {
            onPointChanged: lockSurface.lockRoot.pointerMoved(point.position)
        }
    }

    // black cover for the fade-in at login (Lock.qml: loginCover); on top of the fully drawn lock
    // screen, takes no input, gone (not drawn) once faded
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: lockSurface.lockRoot.loginCover
        visible: opacity > 0
    }

}
