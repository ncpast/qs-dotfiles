import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../Theme"
import "../Utils"

// Notification daemon + popups (replaces swaync). Cards stack at the top right, under the
// top bar. Each card slides in from beyond the left edge of the screen and, when it goes
// away, slides out beyond the right edge; the notification is only removed after that.
// Click: run the default action and dismiss. Right click: dismiss.
Scope {
    id: root

    readonly property int defaultTimeout: 5000   // ms, used when the app doesn't ask for one
    readonly property int criticalTimeout: 10000 // ms, urgent notifications with no timeout of their own
    readonly property int maxTimeout: 10000      // ms, upper limit for app-requested timeouts
    readonly property int cardWidth: 400
    readonly property int gap: 12                // same distance from the top bar and from the right edge
    readonly property int staggerMs: 80          // delay between cards that arrive together

    readonly property int overshootRoom: 60      // window space left of the cards for the bounce

    property string udiskieState: ""             // "mounted" | "unmounted" | "" (last udiskie notification)
    property double nextSlot: 0                  // earliest start time for the next entrance

    // Sound from the theme set in Theme.sound_theme (same one the volume OSD uses).
    // Leading-edge throttle, so a burst of notifications gives one sound, not a pile-up.
    Timer { id: soundCooldown; interval: 400 }

    function playSound(n) {
        if (n.appName === "USB Devices") return      // UsbMonitor plays its own sounds
        if (soundCooldown.running) return
        soundCooldown.start()
        var name = n.urgency === NotificationUrgency.Critical ? "dialog-warning" : "message-new-instant"
        // udiskie: a drive was unmounted / is safe to remove -> its own sound
        if (n.appName === "udiskie" && (n.summary || "").toLowerCase().indexOf("unmounted") !== -1)
            name = "power-unplug"
        Quickshell.execDetached(["paplay", `/usr/share/sounds/${Theme.sound_theme}/stereo/${name}.oga`])
    }

    NotificationServer {
        id: server
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        actionsSupported: true
        keepOnReload: false

        onNotification: n => {
            // udiskie also announces "Device added" / "Device removed" for every drive; UsbMonitor
            // already reports those (for all USB devices), so drop udiskie's copies. Its
            // "Device mounted" / "Device unmounted" messages are the useful ones and stay.
            if (n.appName === "udiskie") {
                var t = (n.summary || "").toLowerCase()
                if (t.indexOf("added") !== -1 || t.indexOf("removed") !== -1) return
                // remember the last mount state, so UsbMonitor knows whether a drive that was
                // just yanked had already been unmounted (udiskie says nothing in that case)
                if (t.indexOf("unmounted") !== -1) root.udiskieState = "unmounted"
                else if (t.indexOf("mounted") !== -1) root.udiskieState = "mounted"
            }
            // Nautilus / gvfs: "<drive> can now be safely unplugged / removed". udiskie's
            // "Device unmounted" already covers this, so drop it.
            var text = ((n.summary || "") + " " + (n.body || "")).toLowerCase()
            if (text.indexOf("safely") !== -1 && (text.indexOf("unplug") !== -1 || text.indexOf("remov") !== -1)) return
            n.tracked = true
            root.playSound(n)
        }
    }

    PanelWindow {
        id: window

        // Stays mapped (mapping/unmapping per notification made the compositor flash a
        // background for a frame). It's fully transparent and only the cards take clicks.
        anchors { top: true; right: true }
        implicitWidth: root.overshootRoom + root.cardWidth + root.gap
        implicitHeight: window.heldHeight
        margins.top: Theme.top_panel_height
        margins.right: Theme.leftBarHidden ? 0 : Theme.spacer_panel_size

        // Height of the stack, but it only ever shrinks after things have settled:
        // resizing a layer surface while cards are moving makes the compositor redraw /
        // reconfigure it mid-animation. It grows immediately so new cards always fit.
        readonly property real wantedHeight: Math.max(1, list.contentHeight + root.gap)
        property real heldHeight: 1
        onWantedHeightChanged: {
            if (wantedHeight > heldHeight) heldHeight = wantedHeight
            else shrinkTimer.restart()
        }
        Timer {
            id: shrinkTimer
            interval: 700
            onTriggered: window.heldHeight = window.wantedHeight
        }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        color: "transparent"
        mask: Region { item: list }

        ListView {
            id: list
            anchors {
                top: parent.top
                topMargin: root.gap
                right: parent.right
                rightMargin: root.gap
            }
            width: root.cardWidth
            height: contentHeight
            interactive: false
            spacing: 0      // each delegate carries its own bottom gap (see slotHeight)
            model: server.trackedNotifications

            delegate: Item {
                id: card
                required property var modelData      // the Notification
                readonly property bool critical: modelData.urgency === NotificationUrgency.Critical

                // entrance / exit state
                property bool shown: false
                property bool leaving: false
                property string leaveAction: "dismiss"     // "dismiss" | "expire"

                // where the card sits relative to the list (x = 0 is its resting place)
                // Enter from, and leave to, beyond the right edge of the screen. The list's right
                // edge is `gap` from the window's right edge, so x = cardWidth + gap puts a card
                // just outside the window.
                readonly property real offscreenRight: root.cardWidth + root.gap + 20

                // The slot the card occupies in the stack: card height + the gap below it.
                // When a card leaves, this shrinks smoothly to 0 *after* the card has slid
                // off screen, so the cards below glide up instead of jumping.
                property real slotFactor: 1
                width: ListView.view.width
                height: (bg.height + 8) * slotFactor

                NumberAnimation {
                    id: collapseAnim
                    target: card
                    property: "slotFactor"
                    to: 0
                    duration: 280
                    easing.type: Easing.InOutCubic
                    onFinished: card.finish()      // only now is the notification removed
                }

                // Slide out first, remove the notification once the card is off screen.
                function close(action) {
                    if (leaving) return
                    leaveAction = action
                    leaving = true
                }

                function finish() {
                    try {
                        if (leaveAction === "expire") modelData.expire()
                        else modelData.dismiss()
                    } catch (e) {}
                }

                Component.onCompleted: {
                    // stagger cards that arrive at the same moment
                    var now = Date.now()
                    var start = Math.max(now, root.nextSlot)
                    root.nextSlot = start + root.staggerMs
                    enterTimer.interval = Math.max(60, start - now)   // let the window map first
                    enterTimer.start()
                }

                Timer {
                    id: enterTimer
                    onTriggered: card.shown = true
                }

                Rectangle {
                    id: bg
                    width: parent.width
                    height: content.implicitHeight + 28
                    radius: 22
                    color: Qt.rgba(Theme.background1.r, Theme.background1.g, Theme.background1.b, 0.68)
                    //border.width: 1
                    //border.color: Qt.rgba(Theme.border_light.r, Theme.border_light.g, Theme.border_light.b, 0.8)

                    // not drawn at all until its entrance starts
                    visible: card.shown || card.leaving

                    x: card.leaving ? card.offscreenRight
                       : card.shown ? 0
                       : card.offscreenRight

                    // Eased instead of SpringAnimation (testing whether that was the choppiness):
                    // OutBack overshoots a little like the spring did; leaving is a plain ease-in.
                    Behavior on x {
                        NumberAnimation {
                            duration: card.leaving ? 260 : 340
                            easing.type: card.leaving ? Easing.InCubic : Easing.OutBack
                            easing.overshoot: 0.9
                        }
                    }

                    // iOS-style feedback: lighter on hover, darker + smaller when pressed
                    scale: mouse.pressed ? 0.9 : 1.0
                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 2 } }

                    // Offscreen rendering is only needed for the hover/press effect; keeping it
                    // on during the slide animations costs frames.
                    layer.enabled: mouse.containsMouse || mouse.pressed
                    layer.effect: MultiEffect {
                        brightness: mouse.pressed ? -0.2 : (mouse.containsMouse ? 0.1 : 0)
                        Behavior on brightness { NumberAnimation { duration: 100; easing.type: Easing.InOutQuad } }
                    }

                    // Off the right edge of the screen: now collapse its slot, then remove it.
                    onXChanged: if (card.leaving && x + list.x >= window.width && !collapseAnim.running
                                    && card.slotFactor === 1) collapseAnim.start()

                    RowLayout {
                        id: content
                        anchors {
                            left: parent.left; right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 16; rightMargin: 16
                        }
                        spacing: 14

                        Image {
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44
                            Layout.alignment: Qt.AlignTop
                            sourceSize: Qt.size(88, 88)
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            asynchronous: true
                            source: {
                                var n = card.modelData
                                // udiskie picks a different icon per event/device (and sometimes one the
                                // theme lacks); use one standard drive icon for all of its messages
                                if (n.appName === "udiskie") return AppIcons.resolve("drive-removable-media-usb")
                                if (n.image) return n.image
                                if (n.appIcon && (n.appIcon.startsWith("/") || n.appIcon.indexOf("://") !== -1))
                                    return n.appIcon.startsWith("/") ? "file://" + n.appIcon : n.appIcon
                                return AppIcons.lookup(n.appIcon) || AppIcons.lookup(n.desktopEntry)
                                    || AppIcons.lookup(n.appName) || AppIcons.resolve("dialog-information")
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: card.critical ? "URGENT" : card.modelData.appName
                                color: card.critical ? Theme.accent : Theme.text
                                font.pixelSize: card.critical ? 11 : 13
                                font.family: "Inter"
                                font.weight: card.critical ? Font.DemiBold : Font.Bold
                                font.letterSpacing: card.critical ? 0.6 : 0
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: card.modelData.summary
                                color: Theme.text
                                font.pixelSize: 13
                                font.family: "Inter"
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: card.modelData.body
                                textFormat: Text.StyledText
                                color: Theme.text
                                opacity: 0.9
                                font.pixelSize: 13
                                font.family: "Inter"
                                wrapMode: Text.WordWrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: event => {
                            var n = card.modelData
                            if (event.button === Qt.LeftButton) {
                                for (var i = 0; i < n.actions.length; i++) {
                                    if (n.actions[i].identifier === "default") {
                                        n.actions[i].invoke()
                                        break
                                    }
                                }
                            }
                            card.close("dismiss")
                        }
                    }

                    // Auto-dismiss once it has arrived; hovering pauses it.
                    Timer {
                        // App-requested timeout (seconds) is honoured but capped, so a card never
                        // lingers; with none requested: 5 s, or 10 s for urgent ones.
                        interval: card.modelData.expireTimeout > 0
                            ? Math.min(card.modelData.expireTimeout * 1000, root.maxTimeout)
                            : (card.critical ? root.criticalTimeout : root.defaultTimeout)
                        running: card.shown && !card.leaving && !mouse.containsMouse
                        onTriggered: card.close("expire")
                    }
                }
            }
        }
    }
}
