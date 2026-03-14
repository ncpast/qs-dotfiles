pragma Singleton
import QtQuick

QtObject {
    /* Light mode
    readonly property color background:  '#f9f5d7'   // bg0_h  — hardest bg, bar base
    readonly property color background1: '#fbf1c7'   // bg0    — default bg
    readonly property color background2: '#f2e5bc'   // bg1    — raised surface

    readonly property color border_light:      '#d5c4a1'   // bg3    — subtle dividers
    readonly property color border:      '#9e9176'   // bg3    — subtle dividers

    readonly property color surface:     '#ebdbb2'   // bg2    — panels / popovers
    readonly property color text:        '#3c3836'   // fg1    — primary text
    readonly property color accent:      '#d65d0e'   // orange — warm gruvbox accent
    */

    /* Dark mode*/
    readonly property int top_panel_height: 33
    readonly property int left_panel_width: 54
    readonly property int spacer_panel_size: 8

    readonly property color background:  '#281d1c'   // hardest bg, bar base
    readonly property color background1: '#312421'   // default bg
    readonly property color background2: '#241b19'   // raised surface

    readonly property color border_light: '#4a3530'  // subtle dividers
    readonly property color border:       '#6b4f49'  // dividers

    readonly property color surface:      '#3d2d2a'  // panels / popovers
    readonly property color text:         '#ebdbb2'  // primary text
    readonly property color accent:       '#d2793e'  // orange (unchanged)

    readonly property int button_radius: 10
    readonly property int concave_radius: 20
    readonly property real button_border_width: 0
    readonly property int widget_spacing: 10
    readonly property int animDuration: 200
    readonly property int colorChangeAnimDuration: 100

    readonly property real bg_lighter: 1.5

    readonly property int button_shadow_radius: 8
    readonly property color button_shadow_color: Qt.rgba(0, 0, 0, 0.15)

    readonly property int animation_speed_desktops: 1000
    //readonly property int active_window_name_offset: 50
}