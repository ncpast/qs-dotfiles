pragma Singleton
import QtQuick

QtObject {
    readonly property string sound_theme: "ocean" // change this to whatever sound theme you have installed 

    readonly property int   top_panel_height: 33
    readonly property int   left_panel_width: 0 + 54
    readonly property int   spacer_panel_size: 0 + 8
    property bool leftBarHidden: true

    // Focus mode (Theme/FocusMode.qml): while the focused workspace is in focus mode,
    // everything goes monotone black & white; otherwise the matugen colours (Colors.qml).
    readonly property bool monotone: FocusMode.active

    readonly property color background:  monotone ? "#000000" : Colors.background
    readonly property color background1: monotone ? "#111111" : Colors.background1
    readonly property color background2: monotone ? "#222222" : Colors.background2

    readonly property color border_light: monotone ? "#333333" : Colors.border_light
    readonly property color border:       monotone ? "#8a8a8a" : Colors.border

    readonly property color surface:      monotone ? "#000000" : Colors.surface
    readonly property color text:         monotone ? "#ffffff" : Colors.text
    readonly property color accent:       monotone ? "#ffffff" : Colors.accent

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

    // MultiEffect drop shadows over the wallpaper (lock screen, desktop icons).
    // blur is a fraction (0..1) of blur_max (px).
    readonly property color shadow_color: Qt.rgba(0, 0, 0, 0.35)
    readonly property real  shadow_blur: 0.6
    readonly property int   shadow_blur_max: 24
    readonly property real  shadow_offset: 2            // px, downwards
    // tighter + darker variant for small text, so captions stay legible
    readonly property color text_shadow_color: Qt.rgba(0, 0, 0, 0.9)
    readonly property real  text_shadow_blur: 0.3
    readonly property int   text_shadow_blur_max: 8
    readonly property real  text_shadow_offset: 1

    readonly property int   animation_speed_desktops: 1000
    //readonly property int active_window_name_offset: 50
}