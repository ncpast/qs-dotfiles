import Quickshell
import Quickshell.Wayland
import "./Bars"
import "./Decor"
import "./Popups/"
import "./Theme"

ShellRoot {
    Visual {}
    
    //EmptyBar {
    //    anchors { bottom: true; left: true; right: true }
    //}

    EmptyBar {
        anchors { top: true; left: true; right: true }
        implicitHeight: Theme.top_panel_height
    }

    EmptyBar {
        anchors { left: true; top: true; bottom: true }
        implicitWidth: Theme.left_panel_width
    }

    //EmptyBar {
    //    anchors { right: true; top: true; bottom: true }
    //}

    //LeftBar { exclusionMode: ExclusionMode.Ignore }
    TopBar { exclusionMode: ExclusionMode.Ignore }
    
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