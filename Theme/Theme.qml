pragma Singleton
import QtQuick

QtObject {
    readonly property string sound_theme: "ocean" // change this to whatever sound theme you have installed 

    readonly property int   top_panel_height: 33
    readonly property int   left_panel_width: 0 + 54
    readonly property int   spacer_panel_size: 0 + 8
    property bool leftBarHidden: true

    readonly property color background:  Colors.background
    readonly property color background1: Colors.background1
    readonly property color background2: Colors.background2

    readonly property color border_light: Colors.border_light
    readonly property color border:       Colors.border

    readonly property color surface:      Colors.surface
    readonly property color text:         Colors.text
    readonly property color accent:       Colors.accent

    property real springStiffness: 6
    property real springDamping: 0.6
    property real springMass: 1
    property real springEpsilon: 0.25

    readonly property int   button_radius: 10
    readonly property int   concave_radius: 20
    readonly property real  button_border_width: 0
    readonly property int   widget_spacing: 10
    readonly property int   animDuration: 200
    readonly property int   colorChangeAnimDuration: 100

    readonly property real  bg_lighter: 1.5

    readonly property int   button_shadow_radius: 8
    readonly property color button_shadow_color: Qt.rgba(0, 0, 0, 0.15)

    readonly property int   animation_speed_desktops: 1000
    //readonly property int active_window_name_offset: 50
}