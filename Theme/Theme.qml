pragma Singleton
import QtQuick

QtObject {
    readonly property string sound_theme: "ocean" // change this to whatever sound theme you have installed 

    readonly property int   top_panel_height: 33
    readonly property int   left_panel_width: 0 + 54
    readonly property int   spacer_panel_size: 0 + 8
    property bool leftBarHidden: true

    // ---- App icon style (desktop + top bar) --------------------------------------------------------
    // If several are on: tinted > coloured > dark mode.
    property bool tintDesktopIcons: false   // iOS "liquid glass": accent tile + glyph, frosted wallpaper behind
    property bool coloredIcons: false       // dark tile, logo in the tile's own colours (Steam: blue on dark)
    property bool darkModeIcons: true       // white parts (logos, tiles) turn desktop_icon_dark_color

    // Per app. Key: any name resolving to the app's icon (icon name, desktop entry id, window class).
    //   darkMode: false    dark mode leaves this app as it is
    //   keepWhite: true    keep white enclosed by the logo (Brave's face) when darkening
    //   coloredIcon: bool  coloured mode for this app or not, overriding coloredIcons
    //   glyphScale: < 1    tinted mode: shrink a symbol that runs off its tile
    readonly property var iconOptions: ({
        "brave":            { keepWhite: true },
        "codium":           { darkMode: false },
        "nautilus":         { keepWhite: true },
        "steam":            { coloredIcon: true },
        "discord":          { coloredIcon: true },
        "counter-strike-2": { coloredIcon: true, glyphScale: 0.8 }
    })

    // dark mode + coloured
    readonly property color desktop_icon_dark_color: Qt.rgba(34 / 255, 34 / 255, 34 / 255, 1)
    readonly property real dark_icon_gradient: 0.13     // tile lighter at the top than the bottom, 0 = flat
    readonly property real dark_icon_rim: 0.3           // light bevel along the edge (top left + bottom right), 0 = none
    // coloured
    readonly property real colored_icon_lift: 0.3       // brighten the logo's colours: 0 = original, 1 = full
    readonly property real colored_icon_highlight: 0.15  // glossy horizontal band across the logo, 0 = none
    // tinted
    readonly property real desktop_icon_tint_opacity: 1     // how visible the tinted icon is
    readonly property real desktop_icon_tile_opacity: 0.55  // dark tile behind the glyph (glass shows through the rest)
    readonly property real desktop_icon_gloss: 0.12         // sheen across the top, 0..~0.3
    readonly property real desktop_icon_glass_opacity: 0.3    // frosting over the blurred glass: 0 = clear, 1 = solid
    readonly property real desktop_icon_glass_blur: 0.5     // 0..1

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

    // Liquid glass rim (Widgets/shaders/glass_rim.frag), everywhere it's used: desktop icons,
    // lock screen field + power buttons, notification button row.
    readonly property real  rim_width: 1        // px
    readonly property real  rim_opacity: 0.2    // its brightest (top) part, 0..1

    // Drop shadows (lock screen, desktop icons, notification cards).
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