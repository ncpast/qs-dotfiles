pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import "../Theme"
import "../Utils"

// An app icon drawn the way the theme says, shared by the desktop and the top bar:
//   normal                      as is
//   Theme.darkModeIcons         white parts darkened (shaders/dark_icon.frag)
//   Theme.coloredIcons          dark tile with the logo in the tile's colour (shaders/colored_icon.frag)
//   Theme.tintDesktopIcons      iOS-style tinted: dark translucent accent tile, bright accent
//                               glyph, gradients and a sheen (shaders/tinted_icon.frag);
//                               with `wallpaper` set, also frosted glass behind it (the wallpaper
//                               under the icon, blurred) and a glass rim highlight
// Every themed layer sits in a Loader that's only active while it's in use, so an icon only ever
// has the items of its current mode.
Item {
    id: root

    property url source
    property size sourceSize: Qt.size(width * 2, height * 2)
    // the app's window class / desktop entry / icon name, for matching per-app settings
    property string appName: ""
    // An Image showing the wallpaper where it is on screen (e.g. Desktop.qml's), in the same window.
    // Set: tinted icons get frosted glass + rim. Unset (top bar): no glass.
    property Image wallpaper: null
    // supersampling for the themed (shader) layers: they render at this many times the icon's size
    // and are scaled down smoothly, which anti-aliases the edges the shaders produce
    property real supersample: 4

    // Is `key` (a name from the settings) this app? Same resolved icon, or the app's name contains
    // the key (ignoring case and punctuation): the same app can resolve to differently named icons,
    // e.g. window class "brave-browser" -> icon "brave-desktop" while "brave" -> icon "brave".
    function isApp(key) {
        if (!key) return false
        const s = source.toString()
        if (s !== "" && AppIcons.resolve(key) === s) return true
        const n = AppIcons._norm(appName), k = AppIcons._norm(key)
        return n !== "" && k !== "" && n.indexOf(k) !== -1
    }

    // this app's icon settings (Theme.iconOptions)
    readonly property var appOptions: {
        const m = Theme.iconOptions
        for (const k in m)
            if (isApp(k)) return m[k]
        return {}
    }

    readonly property bool tinted: Theme.tintDesktopIcons
    // the app's own coloredIcon setting (true or false) overrides the global Theme.coloredIcons
    readonly property bool colored: !tinted && (appOptions.coloredIcon ?? Theme.coloredIcons)
    readonly property bool dark: Theme.darkModeIcons && !tinted && !colored && (appOptions.darkMode ?? true)
    readonly property bool glassy: tinted && wallpaper !== null
    readonly property alias status: img.status

    // ---- Glass (behind the icon) ----------------------------------------------------------------
    // The wallpaper right behind the icon, blurred and cut out in the icon's shape, with a frosting
    // (Theme.desktop_icon_glass_opacity) on top.
    Loader {
        anchors.fill: parent
        active: root.glassy
        sourceComponent: Item {
            id: glass
            visible: root.wallpaper.status === Image.Ready

            // Blurring only the patch right under the icon averages it into one flat colour at
            // strong blur (nothing around it to blend in). So a larger patch, padded by the blur
            // radius on every side, is blurred, and only the middle (the part under the icon) is used.
            readonly property real pad: Math.ceil(glassBlur.blurMax * glassBlur.blur)

            ShaderEffectSource {
                id: glassSource
                x: -glass.pad
                y: -glass.pad
                width: glass.width + 2 * glass.pad
                height: glass.height + 2 * glass.pad
                sourceItem: root.wallpaper
                visible: false
                // The padded patch of wallpaper under the icon. mapToItem isn't reactive, so the
                // position, size and scale of every item up the tree is read here, which makes the
                // binding re-run whenever any of them changes (layout, hover scale, window moves).
                sourceRect: {
                    const w = root.wallpaper
                    let deps = w.x + w.y + w.width + w.height + glass.width + glass.height
                    for (let p = glass; p; p = p.parent) deps += p.x + p.y + p.scale
                    const a = glass.mapToItem(w, -glass.pad, -glass.pad)
                    const b = glass.mapToItem(w, glass.width + glass.pad, glass.height + glass.pad)
                    return Qt.rect(a.x, a.y, b.x - a.x, b.y - a.y)
                }
            }

            MultiEffect {
                id: glassBlur
                anchors.fill: glassSource
                source: glassSource
                autoPaddingEnabled: false
                blurEnabled: true
                blurMax: 32
                blur: Theme.desktop_icon_glass_blur
                visible: false
            }

            // ...and only the part in the icon's shape is shown: the mask is the same padded size,
            // with the icon in the middle
            Item {
                id: glassShape
                anchors.fill: glassSource
                visible: false
                Image {
                    x: glass.pad
                    y: glass.pad
                    width: glass.width
                    height: glass.height
                    source: root.source
                    sourceSize: root.sourceSize
                    asynchronous: true
                }
            }

            OpacityMask {
                anchors.fill: glassSource
                source: glassBlur
                maskSource: glassShape
            }

            // frosting on top of the blur: how strongly the glass blocks the wallpaper
            Rectangle {
                id: glassFrost
                anchors.fill: glassSource
                color: Theme.background
                visible: false
            }

            OpacityMask {
                anchors.fill: glassSource
                source: glassFrost
                maskSource: glassShape
                opacity: Theme.desktop_icon_glass_opacity
                visible: opacity > 0
            }
        }
    }

    // ---- The icon --------------------------------------------------------------------------------
    // as is in normal mode; only the texture for the shaders when themed
    Image {
        id: img
        anchors.fill: parent
        sourceSize: root.sourceSize
        smooth: true
        asynchronous: true
        source: root.source
        visible: !root.tinted && !root.dark && !root.colored
    }

    Loader {
        anchors.fill: parent
        active: root.colored
        sourceComponent: ShaderEffect {
            visible: img.status === Image.Ready
            property variant source: img
            property color darkColor: Theme.desktop_icon_dark_color
            property real keepWhite: root.appOptions.keepWhite ? 1 : 0
            property real lift: Theme.colored_icon_lift
            property real highlight: Theme.colored_icon_highlight
            property real rim: Theme.dark_icon_rim
            property real gradient: Theme.dark_icon_gradient
            fragmentShader: Qt.resolvedUrl("shaders/colored_icon.frag.qsb")
            layer.enabled: true
            layer.smooth: true
            layer.mipmap: true
            layer.textureSize: Qt.size(width * root.supersample, height * root.supersample)
        }
    }

    Loader {
        anchors.fill: parent
        active: root.dark
        sourceComponent: ShaderEffect {
            visible: img.status === Image.Ready
            property variant source: img
            property color darkColor: Theme.desktop_icon_dark_color
            property real keepWhite: root.appOptions.keepWhite ? 1 : 0
            property real rimStrength: Theme.dark_icon_rim
            property real gradient: Theme.dark_icon_gradient
            fragmentShader: Qt.resolvedUrl("shaders/dark_icon.frag.qsb")
            layer.enabled: true
            layer.smooth: true
            layer.mipmap: true
            layer.textureSize: Qt.size(width * root.supersample, height * root.supersample)
        }
    }

    Loader {
        anchors.fill: parent
        active: root.tinted
        sourceComponent: ShaderEffect {
            visible: img.status === Image.Ready
            opacity: Theme.desktop_icon_tint_opacity
            property variant source: img
            property color tint: Theme.accent
            property real tileOpacity: Theme.desktop_icon_tile_opacity
            property real gloss: Theme.desktop_icon_gloss
            property real glyphScale: root.appOptions.glyphScale ?? 1
            fragmentShader: Qt.resolvedUrl("shaders/tinted_icon.frag.qsb")
            layer.enabled: true
            layer.smooth: true
            layer.mipmap: true
            layer.textureSize: Qt.size(width * root.supersample, height * root.supersample)
        }
    }

    // ---- Glass rim (on top) ----------------------------------------------------------------------
    // A thin highlight along the icon's edge, brightest at the top (lit from above) with a faint lift
    // at the bottom (shaders/glass_rim.frag); supersampled like the other shader layers, so it's
    // anti-aliased.
    Loader {
        anchors.fill: parent
        active: root.glassy
        sourceComponent: ShaderEffect {
            visible: img.status === Image.Ready
            property variant source: img
            property size texel: Qt.size(1 / Math.max(1, root.width), 1 / Math.max(1, root.height))
            property real rimPx: Theme.rim_width
            property real strength: Theme.rim_opacity
            fragmentShader: Qt.resolvedUrl("shaders/glass_rim.frag.qsb")
            layer.enabled: true
            layer.smooth: true
            layer.mipmap: true
            layer.textureSize: Qt.size(root.width * root.supersample, root.height * root.supersample)
        }
    }
}
