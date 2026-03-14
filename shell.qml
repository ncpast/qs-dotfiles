import Quickshell
import Quickshell.Wayland
import "./Bars"
import "./Decor"
import "./Popups/"

ShellRoot {
    Visual {}
    TopBar {}
    LeftBar {}
    
    EmptyBar {
        anchors { bottom: true; left: true; right: true }
    }

    EmptyBar {
        anchors { right: true; top: true; bottom: true }
    }
    
    PowerOverlay {
        id: powerOverlay
    }

    // Corner { anchors { top: true;    left: true  } cornerRotation: 180 }
    // Corner { anchors { top: true;    right: true } cornerRotation: 270 }
    // Corner { anchors { bottom: true; left: true  } cornerRotation: 90  }
    // Corner { anchors { bottom: true; right: true } cornerRotation: 0   } 

    Corner { anchors { top: true;    left: true  } cornerRotation: 180; curveColor: "black"; exclusionMode: ExclusionMode.Ignore; WlrLayershell.layer: WlrLayer.Overlay; radius: 14 }
    Corner { anchors { top: true;    right: true } cornerRotation: 270; curveColor: "black"; exclusionMode: ExclusionMode.Ignore; WlrLayershell.layer: WlrLayer.Overlay; radius: 14 }
    Corner { anchors { bottom: true; left: true  } cornerRotation: 90;  curveColor: "black"; exclusionMode: ExclusionMode.Ignore; WlrLayershell.layer: WlrLayer.Overlay; radius: 14 }
    Corner { anchors { bottom: true; right: true } cornerRotation: 0;   curveColor: "black"; exclusionMode: ExclusionMode.Ignore; WlrLayershell.layer: WlrLayer.Overlay; radius: 14 }
}