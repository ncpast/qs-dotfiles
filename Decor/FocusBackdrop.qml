import Quickshell
import Quickshell.Wayland
import QtQuick
import "../Theme"

// Focus mode: a black backdrop over the wallpaper while the focused workspace is in focus
// mode. It sits on the Bottom layer: above the wallpaper and the desktop icons (Background
// layer), below windows and the bar.
//
// Performance: the window only exists while it's needed (an always-mapped transparent
// full-screen layer costs a full-screen blend every frame), and the fade in / out is done
// by Hyprland's layer animation (layer rule `animation = "fade"` for quickshell-focusbg),
// so Quickshell draws a single black frame instead of re-rendering the screen per frame.
Variants {
    model: Quickshell.screens

    PanelWindow {
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell-focusbg"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region {}
        color: "black"
        visible: Theme.monotone
    }
}
