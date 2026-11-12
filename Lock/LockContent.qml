pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import "../Theme"

// The lockscreen UI. Shown both on the real lock surfaces (LockSurface.qml) and on the
// fade overlay (Lock.qml) that animates it in/out over the desktop, so the two must look
// identical. All state lives in Lock.qml (lockRoot).
Item {
    id: surface
    required property var lockRoot
    property bool interactive: true      // false on the fade overlay: no keyboard focus

    // "typing mode": login box centered + scaled, wallpaper blurred
    readonly property bool typing: lockRoot.password.length > 0

    Item {
        id: content
        anchors.fill: parent

        // ---- Background ---------------------------------------------------------

        Rectangle {
            anchors.fill: parent
            color: Theme.background
        }

        // Synchronous + cached: Lock.qml preloads this exact image before showing
        // anything, so it is already decoded and never flashes the fallback colour.
        Image {
            id: wall
            anchors.fill: parent
            source: surface.lockRoot.wallpaperUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: false
            cache: true
            visible: false
        }

        MultiEffect {
            anchors.fill: parent
            source: wall
            visible: wall.status === Image.Ready
            autoPaddingEnabled: false
            blurEnabled: true
            blurMax: 64
            blur: surface.typing ? 1 : 0
            brightness: surface.typing ? -0.08 : 0
            Behavior on blur { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
            Behavior on brightness { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
        }

        // subtle darkening at the bottom so the name / field stay readable
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * 0.4
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.3) }
            }
        }

        // ---- Date + clock -------------------------------------------------------

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        // The clock is frosted glass in the shape of the digits: the wallpaper behind it,
        // blurred and masked by the text, with a translucent Theme.accent tint on top.
        Item {
            id: clockBox
            anchors.horizontalCenter: parent.horizontalCenter
            // fades out in step with the login box sliding up (t: 0 resting → 1 centered;
            // clamped because the spring overshoots)
            opacity: 1 - Math.max(0, Math.min(1, loginBox.t))
            visible: opacity > 0
            anchors.top: parent.top
            // the padding is part of the box (and of every offscreen layer below), so glyphs
            // that reach past their text bounds (the -4 letter spacing makes the last digit
            // overhang) aren't chopped off; topMargin is adjusted so the clock doesn't move
            anchors.topMargin: parent.height * 0.08 - clockText.padding
            width: clockText.implicitWidth
            height: clockText.implicitHeight

            // the text itself, only used as the mask / tint source
            Column {
                id: clockText
                anchors.fill: parent
                padding: 24
                spacing: -10
                visible: false
                layer.enabled: true
                layer.smooth: true

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(clock.date, "ddd MMM d")
                    color: "white"
                    font.family: "Inter"
                    font.weight: Font.DemiBold
                    font.pixelSize: 26
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(clock.date, "HH:mm")
                    color: "white"
                    font.family: "Inter"
                    font.weight: Font.Bold
                    font.pixelSize: 140
                    font.letterSpacing: -4
                }
            }

            ShaderEffectSource {
                id: clockGlassSource
                anchors.fill: parent
                sourceItem: wall
                visible: false
                sourceRect: {
                    var deps = clockBox.width + clockBox.height + clockBox.y
                    var a = clockBox.mapToItem(wall, 0, 0)
                    return Qt.rect(a.x, a.y, clockBox.width, clockBox.height)
                }
            }

            // blurred wallpaper (rendered offscreen only, cut out below)
            MultiEffect {
                id: clockBlur
                anchors.fill: parent
                source: clockGlassSource
                autoPaddingEnabled: false
                blurEnabled: true
                blurMax: 32
                blur: 1
                brightness: 0.1
                visible: false
                layer.enabled: true
                layer.smooth: true
            }

            // ...cut out in the exact (anti-aliased) shape of the glyphs
            OpacityMask {
                anchors.fill: parent
                source: clockBlur
                maskSource: clockText
            }

            // accent tint on top
            MultiEffect {
                anchors.fill: parent
                source: clockText
                colorization: 1
                colorizationColor: Theme.accent
                opacity: 0.6
            }
        }

        // ---- Login box: avatar, name, password, power buttons -------------------

        Column {
            id: loginBox
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10
            transformOrigin: Item.Center

            // Only the typing transition is animated (0 = resting at the bottom, 1 = centered).
            // Position/size changes themselves apply instantly, so the box doesn't fly in
            // from the top when the window first gets its size.
            property real t: surface.typing ? 1 : 0
            Behavior on t {
                SpringAnimation {
                    spring: Theme.springStiffness
                    damping: Theme.springDamping
                    mass: Theme.springMass
                    epsilon: 0.002
                }
            }
            // t clamped to 0..1 (the spring overshoots) - drives the fades tied to typing
            readonly property real tc: Math.max(0, Math.min(1, t))

            readonly property real restY: parent.height - height - parent.height * 0.06
            readonly property real centerY: (parent.height - height) / 2
            y: restY + (centerY - restY) * t
            readonly property real typingZoom: 1.2      // whole box, while typing
            scale: 1 + (typingZoom - 1) * t

            // Avatar (~/.face), initial letter on an accent circle as a fallback.
            // Shrinking keeps it sharp, enlarging blurs it, so it's rendered at its biggest size and
            // scaled down from there. The outer item takes the size it shows at, so the name and
            // field below move with it.
            Item {
                id: avatarBox
                anchors.horizontalCenter: parent.horizontalCenter
                readonly property real restSize: 64     // px at rest
                readonly property real zoom: 1.5        // size while typing, as a multiple of restSize
                readonly property real fullSize: restSize * zoom * loginBox.typingZoom
                readonly property real shownSize: restSize * (1 + (zoom - 1) * loginBox.t)
                width: shownSize
                height: width

                Item {
                    width: avatarBox.fullSize
                    height: avatarBox.fullSize
                    anchors.centerIn: parent
                    scale: avatarBox.shownSize / avatarBox.fullSize

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Theme.accent
                        visible: avatar.status !== Image.Ready

                        Text {
                            anchors.centerIn: parent
                            text: surface.lockRoot.displayName.charAt(0).toUpperCase()
                            color: "white"
                            font.family: "Inter"
                            font.weight: Font.Bold
                            font.pixelSize: parent.width * 0.44
                        }
                    }

                    Image {
                        id: avatar
                        anchors.fill: parent
                        source: "file://" + Quickshell.env("HOME") + "/.face"
                        // render size at up to 2x screen scale
                        sourceSize: Qt.size(avatarBox.fullSize * 2, avatarBox.fullSize * 2)
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        visible: false
                    }

                    Rectangle {
                        id: avatarMask
                        anchors.fill: parent
                        radius: width / 2
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: avatar
                        maskSource: avatarMask
                        visible: avatar.status === Image.Ready
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: surface.lockRoot.displayName
                color: Theme.text
                font.family: "Inter"
                font.weight: Font.DemiBold
                font.pixelSize: 15
            }

            // Password field
            Rectangle {
                id: field
                anchors.horizontalCenter: parent.horizontalCenter
                width: 160
                height: 30
                radius: height / 2
                color: "transparent"
                opacity: surface.lockRoot.busy && !surface.lockRoot.unlocking ? 0.6 : 1

                transform: Translate { id: shakeOffset }

                // Frosted glass: the wallpaper behind the field, blurred and clipped to the pill.
                // Glass, tint and border are hidden at rest and fade in as you start typing.
                Item {
                    id: fieldGlass
                    anchors.fill: parent
                    opacity: loginBox.tc
                    visible: opacity > 0

                    // the shadow is taken from the composited (opaque) glass pill, so it only
                    // shows around the outside and fades together with the glass
                    layer.enabled: visible
                    layer.smooth: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Theme.shadow_color
                        shadowBlur: Theme.shadow_blur
                        blurMax: Theme.shadow_blur_max
                        shadowVerticalOffset: Theme.shadow_offset
                    }

                    ShaderEffectSource {
                        id: fieldGlassSource
                        anchors.fill: parent
                        sourceItem: wall
                        visible: false
                        // Re-maps while the box moves / scales and while the field shakes.
                        sourceRect: {
                            var deps = loginBox.y + loginBox.scale + shakeOffset.x
                            var a = fieldGlass.mapToItem(wall, 0, 0)
                            var b = fieldGlass.mapToItem(wall, fieldGlass.width, fieldGlass.height)
                            return Qt.rect(a.x, a.y, b.x - a.x, b.y - a.y)
                        }
                    }

                    Rectangle {
                        id: fieldGlassMask
                        anchors.fill: parent
                        radius: field.radius
                        visible: false
                        layer.enabled: true
                        layer.smooth: true
                    }

                    MultiEffect {
                        id: fieldGlassBlur
                        anchors.fill: parent
                        source: fieldGlassSource
                        autoPaddingEnabled: false
                        blurEnabled: true
                        blurMax: 32
                        blur: 1
                        visible: false
                        layer.enabled: true
                        layer.smooth: true
                    }

                    // OpacityMask uses the mask's real (anti-aliased) alpha; MultiEffect's mask
                    // is a hard threshold, which made the edges jagged
                    OpacityMask {
                        anchors.fill: parent
                        source: fieldGlassBlur
                        maskSource: fieldGlassMask
                    }
                }

                // Tint + border on top of the glass
                Rectangle {
                    anchors.fill: parent
                    radius: field.radius
                    opacity: loginBox.tc
                    visible: opacity > 0
                    color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.8)
                }

                // liquid glass rim (Widgets/shaders/glass_rim.frag), drawn from a hidden copy of the shape;
                // supersampled so it's anti-aliased
                Rectangle {
                    id: fieldRimShape
                    anchors.fill: parent
                    radius: field.radius
                    visible: false
                    layer.enabled: true
                    layer.smooth: true
                    layer.textureSize: Qt.size(width * 4, height * 4)
                }
                ShaderEffect {
                    anchors.fill: parent
                    opacity: loginBox.tc
                    visible: opacity > 0
                    property variant source: fieldRimShape
                    property size texel: Qt.size(1 / Math.max(1, width), 1 / Math.max(1, height))
                    property real rimPx: Theme.rim_width
                    property real strength: Theme.rim_opacity
                    fragmentShader: Qt.resolvedUrl("../Widgets/shaders/glass_rim.frag.qsb")
                    layer.enabled: true
                    layer.smooth: true
                    layer.mipmap: true
                    layer.textureSize: Qt.size(width * 4, height * 4)
                }

                SequentialAnimation {
                    id: shake
                    loops: 1
                    NumberAnimation { target: shakeOffset; property: "x"; to: -12; duration: 50 }
                    NumberAnimation { target: shakeOffset; property: "x"; to: 12; duration: 70 }
                    NumberAnimation { target: shakeOffset; property: "x"; to: -8; duration: 60 }
                    NumberAnimation { target: shakeOffset; property: "x"; to: 8; duration: 60 }
                    NumberAnimation { target: shakeOffset; property: "x"; to: 0; duration: 50 }
                }

                Connections {
                    target: surface.lockRoot
                    function onFailCountChanged() { shake.restart() }
                }

                Text {
                    anchors.centerIn: parent
                    visible: input.text.length === 0
                    text: surface.lockRoot.failed ? "Incorrect Password" : "Enter Password"
                    color: Qt.darker(Theme.text, 1.3)
                    font.family: "Inter"
                    font.weight: 600
                    font.pixelSize: 13
                }

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    horizontalAlignment: TextInput.AlignHCenter
                    clip: true
                    focus: surface.interactive
                    enabled: surface.interactive && !surface.lockRoot.busy
                    echoMode: TextInput.Password
                    passwordCharacter: "●"
                    cursorDelegate: Item {}          // no blinking | cursor
                    color: Theme.text
                    selectionColor: Qt.rgba(1, 1, 1, 0.3)
                    font.family: "Inter"
                    font.pixelSize: 8
                    font.letterSpacing: 2

                    text: surface.lockRoot.password
                    onTextEdited: surface.lockRoot.password = text

                    Keys.onReturnPressed: surface.lockRoot.submit()
                    Keys.onEnterPressed: surface.lockRoot.submit()
                    Keys.onEscapePressed: surface.lockRoot.password = ""

                    Component.onCompleted: if (enabled) forceActiveFocus()
                    onEnabledChanged: if (enabled) forceActiveFocus()
                    // re-grab focus whenever the surface gets activated again (e.g. after a
                    // suspend, when the output comes back) and right after resuming
                    Window.onActiveChanged: if (Window.active && enabled) forceActiveFocus()
                    Connections {
                        target: surface.lockRoot
                        function onResumed() { if (input.enabled) input.forceActiveFocus() }
                    }
                }
            }

            // Power buttons: hidden at rest, fade in as the box slides up (they keep their space, so the
            // box doesn't jump), and take no clicks while hidden
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: loginBox.tc
                enabled: opacity > 0        // not `visible`: the Column would drop it and the box would jump
                topPadding: 8
                spacing: 18

                Repeater {
                    model: [
                        { letter: "", label: "Shut Down", command: ["systemctl", "poweroff"] },
                        { letter: "", label: "Reboot",    command: ["systemctl", "reboot"] },
                        { letter: "󰤄", label: "Suspend",   command: [Quickshell.env("HOME") + "/.config/hypr/scripts/suspend.sh"] }
                    ]

                    Item {

                        
                        id: powerButtonContainer
                        required property var modelData
                        width: 40
                        height: 40

                        Item {
                            anchors.fill: parent

                            // Button background (glass + tint), shown on hover / press.
                            // Shaded like the notification cards: lighter on hover, darker when
                            // pressed; the brightness is animated here and the effect follows it.
                            Item {
                                id: buttonBg
                                anchors.fill: parent
                                opacity: 1
                                scale: buttonMouse.pressed ? 0.9 : (buttonMouse.containsMouse ? 1.2 : 1)
                                Behavior on opacity { NumberAnimation { duration: 100 } }
                                Behavior on scale { NumberAnimation { duration: 100 } }

                                // 100 ms when it darkens for a press, 50 ms otherwise
                                readonly property real shadeTarget: buttonMouse.pressed ? -0.05 : (buttonMouse.containsMouse ? 0.05 : 0)
                                property real shade: shadeTarget
                                Behavior on shade { NumberAnimation { duration: buttonBg.shadeTarget < 0 ? 100 : 50; easing.type: Easing.InOutQuad } }
                                layer.enabled: visible
                                layer.smooth: true
                                layer.effect: MultiEffect {
                                    brightness: buttonBg.shade
                                    shadowEnabled: true
                                    shadowColor: Theme.shadow_color
                                    shadowBlur: Theme.shadow_blur
                                    blurMax: Theme.shadow_blur_max
                                    shadowVerticalOffset: Theme.shadow_offset
                                }

                                // Frosted glass: the wallpaper right behind the button, blurred and
                                // clipped to a circle.
                                Item {
                                    id: glass
                                    anchors.fill: parent

                                    ShaderEffectSource {
                                        id: glassSource
                                        anchors.fill: parent
                                        sourceItem: wall
                                        visible: false
                                        // The patch of wallpaper under this button. loginBox.y / scale are
                                        // referenced so it re-maps while the box moves and scales.
                                        sourceRect: {
                                            var deps = loginBox.y + loginBox.scale + (buttonBg.visible ? 1 : 0)
                                            var a = glass.mapToItem(wall, 0, 0)
                                            var b = glass.mapToItem(wall, glass.width, glass.height)
                                            return Qt.rect(a.x, a.y, b.x - a.x, b.y - a.y)
                                        }
                                    }

                                    Rectangle {
                                        id: glassMask
                                        anchors.fill: parent
                                        radius: width / 2
                                        visible: false
                                        layer.enabled: true
                                        layer.smooth: true
                                    }

                                    MultiEffect {
                                        id: glassBlur
                                        anchors.fill: parent
                                        source: glassSource
                                        autoPaddingEnabled: false
                                        blurEnabled: true
                                        blurMax: 32
                                        blur: 1
                                        visible: false
                                        layer.enabled: true
                                        layer.smooth: true
                                    }

                                    // anti-aliased cut-out (see the password field)
                                    OpacityMask {
                                        anchors.fill: parent
                                        source: glassBlur
                                        maskSource: glassMask
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: width / 2
                                    color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.68)
                                }

                                // liquid glass rim (Widgets/shaders/glass_rim.frag), drawn from a hidden copy of the shape;
                                // supersampled so it's anti-aliased
                                Rectangle {
                                    id: buttonRimShape
                                    anchors.fill: parent
                                    radius: width / 2
                                    visible: false
                                    layer.enabled: true
                                    layer.smooth: true
                                    layer.textureSize: Qt.size(width * 4, height * 4)
                                }
                                ShaderEffect {
                                    anchors.fill: parent
                                    property variant source: buttonRimShape
                                    property size texel: Qt.size(1 / Math.max(1, width), 1 / Math.max(1, height))
                                    property real rimPx: Theme.rim_width
                                    property real strength: Theme.rim_opacity
                                    fragmentShader: Qt.resolvedUrl("../Widgets/shaders/glass_rim.frag.qsb")
                                    layer.enabled: true
                                    layer.smooth: true
                                    layer.mipmap: true
                                    layer.textureSize: Qt.size(width * 4, height * 4)
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: powerButtonContainer.modelData.letter
                                color: Theme.text
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 18
                                scale: buttonMouse.pressed ? 0.9 : (buttonMouse.containsMouse ? 1.2 : 1)
                                Behavior on scale { NumberAnimation { duration: 100 } }

                                layer.enabled: buttonBg.shade !== 0
                                layer.smooth: true
                                layer.effect: MultiEffect {
                                    brightness: buttonBg.shade
                                }
                            }

                            MouseArea {
                                id: buttonMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(powerButtonContainer.modelData.command)
                            }
                        }

                        Text {
                            anchors.horizontalCenter: powerButtonContainer.horizontalCenter
                            anchors.top: powerButtonContainer.bottom
                            anchors.topMargin: 12
                            text: powerButtonContainer.modelData.label
                            color: Theme.text
                            font.family: "Inter"
                            font.weight: 600
                            font.pixelSize: 10
                            opacity: buttonMouse.containsMouse ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                    }
                }
            }
        }
    }

    // Fade to black before suspending, back from black after resuming (Lock.qml: dim)
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: surface.lockRoot.dim
        visible: opacity > 0
    }
}
