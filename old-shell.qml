import Quickshell
import "./bars"
import "./corners"

ShellRoot {
    TopBar {}
    LeftBar {}
    EmptyBar {
      anchors {
        bottom: true; left: true; right: true }
    }

    PowerOverlay {
        id: powerOverlay
    }

    EmptyBar {
      anchors { right: true; top: true; bottom: true }
    }
    
    // top-left
    Corner {
        anchors { top: true; left: true }
        cornerRotation: 180
    }

    // top-right
    Corner {
        anchors { top: true; right: true }
        cornerRotation: 270
    }

    // bottom-left
    Corner {
        anchors { bottom: true; left: true }
        cornerRotation: 90
    }

    // bottom-right 
    Corner {
        anchors { bottom: true; right: true }
        cornerRotation: 0
    }
    // BLACK CORNERS

    Corner {
        anchors { bottom: true; right: true }
        cornerRotation: 0
        curveColor: "black"
        exclusionMode: ExclusionMode.Ignore
        radius: 14
    }

    Corner {
        anchors { top: true; left: true }
        cornerRotation: 180
        curveColor: "black"
        exclusionMode: ExclusionMode.Ignore
        radius: 14
    }

    // top-right
    Corner {
        anchors { top: true; right: true }
        cornerRotation: 270
        curveColor: "black"
        exclusionMode: ExclusionMode.Ignore
        radius: 14
    }

    // bottom-left
    Corner {
        anchors { bottom: true; left: true }
        cornerRotation: 90
        curveColor: "black"
        exclusionMode: ExclusionMode.Ignore
        radius: 14
    }
}