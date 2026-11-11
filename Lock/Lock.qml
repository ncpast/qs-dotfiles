import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import "../Utils"

// Session lock: `qs ipc call lock lock` (SUPER+L, menu) or idle.
// Suspend: `qs ipc call lock suspend` (suspend.sh, lockscreen button): lock, fade to
// black, suspend; on resume (logind PrepareForSleep false) reset + refocus + fade back.
// The password state is shared, so every monitor shows the same field.
//
// Hyprland draws black behind a session-lock surface, so the lock itself can't fade
// over the desktop. Instead a normal overlay layer showing the identical UI fades in,
// then the real lock takes over; on unlock the overlay is shown again, the lock is
// released underneath it, and the overlay fades out to the desktop.
Scope {
    id: root

    property string password: ""
    property bool busy: false            // PAM is checking (or we're unlocking)
    property bool failed: false          // last attempt was wrong
    property int failCount: 0            // bumps on every failure (the field shakes on change)

    // screen-sized copy of the current wallpaper (Utils/Wallpaper.qml keeps it up to date, so the
    // overlay's Image has it decoded before a lock starts)
    readonly property string wallpaperUrl: Wallpaper.urlFor(Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "")

    readonly property string user: Quickshell.env("USER")
    property string displayName: user

    // fade overlay state
    property bool overlayShown: false
    property real fade: 0
    property bool pendingLock: false     // lock requested, fade-in not started yet
    property bool unlocking: false

    readonly property int fadeInDuration: 350
    readonly property int fadeOutDuration: 450

    // suspend state
    property real dim: 0                 // black fade over the lockscreen before sleeping
    property bool pendingSuspend: false  // suspend requested, waiting for the lock to be secure
    readonly property string scriptDir: Quickshell.env("HOME") + "/.config/hypr/scripts"
    signal resumed()                     // surfaces re-grab keyboard focus on this

    function suspend() {
        if (pendingSuspend || dim > 0) return
        pendingSuspend = true
        // a half-typed password shouldn't survive the sleep
        if (!unlocking) { password = ""; failed = false }
        if (sessionLock.secure) beginDim()
        else lock()                      // continues from onSecureChanged
    }

    function beginDim() {
        pendingSuspend = false
        undimAnim.stop()
        dimAnim.restart()
    }

    function handleResume() {
        pendingSuspend = false
        dimAnim.stop()
        password = ""
        failed = false
        busy = false
        Quickshell.execDetached([scriptDir + "/suspend.sh", "--resumed"])
        resumed()
        if (dim > 0) undimAnim.restart()
    }

    function lock() {
        if (sessionLock.locked || overlayShown || pendingLock) return
        password = ""
        failed = false
        busy = false
        pendingLock = true
        beginFadeIn()
    }

    function beginFadeIn() {
        if (!pendingLock) return
        pendingLock = false
        fadeOutAnim.stop()
        fade = 0
        overlayShown = true
        fadeInAnim.restart()
    }

    function submit() {
        if (busy || password.length === 0) return
        busy = true
        failed = false
        pam.start()
    }

    function beginUnlock() {
        unlocking = true                 // keeps the field (dots, centered box) as-is while fading
        fadeInAnim.stop()
        fade = 1
        overlayShown = true
        releaseTimer.restart()           // give the overlay a frame to map before unlocking
    }

    NumberAnimation {
        id: fadeInAnim
        target: root
        property: "fade"
        to: 1
        duration: root.fadeInDuration
        easing.type: Easing.OutCubic
        onFinished: sessionLock.locked = true
    }

    Timer {
        id: releaseTimer
        interval: 60
        onTriggered: {
            sessionLock.locked = false
            fadeOutAnim.restart()
        }
    }

    NumberAnimation {
        id: fadeOutAnim
        target: root
        property: "fade"
        to: 0
        duration: root.fadeOutDuration
        easing.type: Easing.InOutCubic
        onFinished: {
            root.overlayShown = false
            root.unlocking = false
            root.busy = false
            root.password = ""
            root.failed = false
        }
    }

    NumberAnimation {
        id: dimAnim
        target: root
        property: "dim"
        to: 1
        duration: 300
        easing.type: Easing.InCubic
        // the screen is black now: do the actual suspend (suspend.sh --now)
        onFinished: Quickshell.execDetached([root.scriptDir + "/suspend.sh", "--now"])
    }

    NumberAnimation {
        id: undimAnim
        target: root
        property: "dim"
        to: 0
        duration: 500
        easing.type: Easing.OutCubic
    }

    // logind: "PrepareForSleep (false,)" = just woke up, "(true,)" = about to sleep
    // (lid close etc. that didn't go through suspend(): lock, best effort).
    Process {
        running: true
        // Wrapped so gdbus can't be orphaned: the shell kills it on SIGTERM (quickshell
        // reload/exit), and polls quickshell ($PPID) so it also exits when quickshell is
        // killed outright. (setpriv --pdeathsig didn't work for this.)
        command: ["sh", "-c",
            "gdbus monitor --system --dest org.freedesktop.login1 --object-path /org/freedesktop/login1 & g=$!; " +
            "trap 'kill $g 2>/dev/null' EXIT INT TERM; " +
            "while kill -0 $PPID 2>/dev/null && kill -0 $g 2>/dev/null; do sleep 2; done"]
        stdout: SplitParser {
            onRead: line => {
                if (line.indexOf("PrepareForSleep") === -1) return
                if (line.indexOf("false") !== -1) root.handleResume()
                else if (!root.pendingSuspend && root.dim === 0) root.lock()
            }
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: false

        // the lock surfaces now cover everything; the overlay underneath isn't needed
        onSecureChanged: {
            if (secure && !root.unlocking) root.overlayShown = false
            if (secure && root.pendingSuspend) root.beginDim()
        }

        LockSurface {
            lockRoot: root
        }
    }

    // Fade overlay, one per screen. It stays alive while hidden, so its (cached,
    // synchronous) wallpaper Image is already decoded before a lock starts.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            visible: root.overlayShown
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-lock"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors { top: true; bottom: true; left: true; right: true }

            LockContent {
                anchors.fill: parent
                lockRoot: root
                interactive: false
                opacity: root.fade
            }
        }
    }

    PamContext {
        id: pam
        config: "login"
        user: root.user

        onResponseRequiredChanged: {
            if (responseRequired) respond(root.password)
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.failed = false
                root.beginUnlock()
            } else {
                root.busy = false
                root.password = ""
                root.failed = true
                root.failCount++
            }
        }

        onError: err => {
            root.busy = false
            root.password = ""
            root.failed = true
            root.failCount++
            console.warn("lock: PAM error", err)
        }
    }

    // Real name from passwd (GECOS), falls back to $USER.
    Process {
        running: true
        command: ["getent", "passwd", root.user]
        stdout: SplitParser {
            onRead: line => {
                var gecos = (line.split(":")[4] || "").split(",")[0].trim()
                if (gecos !== "") root.displayName = gecos
            }
        }
    }

    IdleMonitor {
        timeout: 300
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) root.lock()
    }

    IpcHandler {
        target: "lock"
        function lock(): void { root.lock() }
        function suspend(): void { root.suspend() }
    }
}
