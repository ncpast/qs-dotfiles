// Big wallpapers (e.g. 8K 16-bit PNGs) exceed Qt's default 256 MB image decode limit and fail to
// load (desktop icon glass, lock screen). Applied at launch, so it needs a full restart.
//@ pragma Env QT_IMAGEIO_MAXALLOC=1024
import Quickshell
import Quickshell.Wayland
import QtQuick
import "./Bars"
import "./Decor"
import "./Desktop"
import "./Popups/"
import "./Theme"
import "./Utils"
import "./OSD"
import "./Notifications"
import "./Lock"
import "./apps/settings"
import "./apps/calculator"

ShellRoot {
    // The lock comes first; at a greetd autologin everything else waits until it covers the
    // screens (Lock.holdDesktop), so nothing is drawn before the lock screen.
    Lock { id: lock }

    // 60 Hz on the power-saver profile (outside the loader: applies at the lock screen too)
    RefreshRate {}

    // The frame (Visual) and the bars share Hyprland's Top layer, where whichever surface appears
    // last is drawn on top. Normally they're created together, frame first. At a greetd autologin,
    // when everything is created at once behind the lock, the frame tended to appear last and hid
    // the bars; so there the bars follow half a second later (still behind the lock).
    LazyLoader {
        active: !lock.holdDesktop
        Visual {}
    }
    property bool barsAfterFrame: !lock.loginStart
    Timer {
        running: lock.loginStart && !lock.holdDesktop
        interval: 500
        onTriggered: barsAfterFrame = true
    }

    LazyLoader {
        active: !lock.holdDesktop && barsAfterFrame

        Scope {
            VolumeOSD {}
            Desktop {}
            FocusBackdrop {}
            Notifications { id: notifications }
            UsbMonitor { notifications: notifications }
            Settings {}
            Calculator {}
    
            EmptyBar {
                anchors { bottom: true; left: true; right: true }
                implicitHeight: Theme.leftBarHidden ? 0 : Theme.spacer_panel_size
            }

            EmptyBar {
                anchors { top: true; left: true; right: true }
                implicitHeight: Theme.top_panel_height
            }

            EmptyBar {
                anchors { left: true; top: true; bottom: true }
                implicitWidth: Theme.leftBarHidden ? 0 : Theme.left_panel_width
            }

            EmptyBar {
                anchors { right: true; top: true; bottom: true; }
                implicitWidth: Theme.leftBarHidden ? 0 : Theme.spacer_panel_size
            }

            LeftBar { exclusionMode: ExclusionMode.Ignore }
            TopBar { exclusionMode: ExclusionMode.Ignore }
    
            PowerOverlay {
                id: powerOverlay
            }

            // Corner { anchors { top: true;    left: true  } cornerRotation: 180 }
            // Corner { anchors { top: true;    right: true } cornerRotation: 270 }
            // Corner { anchors { bottom: true; left: true  } cornerRotation: 90  }
            // Corner { anchors { bottom: true; right: true } cornerRotation: 0   } 

            Corner { anchors { top: true;    left: true  } cornerRotation: 180; curveColor: "black"; exclusionMode: ExclusionMode.Ignore; WlrLayershell.layer: WlrLayer.Overlay; radius: 14; }
            Corner { anchors { top: true;    right: true } cornerRotation: 270; curveColor: "black"; exclusionMode: ExclusionMode.Ignore; WlrLayershell.layer: WlrLayer.Overlay; radius: 14; }
            Corner { anchors { bottom: true; left: true  } cornerRotation: 90;  curveColor: "black"; exclusionMode: ExclusionMode.Ignore; WlrLayershell.layer: WlrLayer.Overlay; radius: 14; visible: !Theme.monotone }
            Corner { anchors { bottom: true; right: true } cornerRotation: 0;   curveColor: "black"; exclusionMode: ExclusionMode.Ignore; WlrLayershell.layer: WlrLayer.Overlay; radius: 14; visible: !Theme.monotone }
        }
    }
}