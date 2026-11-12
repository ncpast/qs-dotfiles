import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import "../Utils"

// Session lock: `qs ipc call lock lock` (SUPER+L, menu) or idle.
// `qs ipc call lock lockNow`: same, but instantly (no fade). At login (greetd autologin) the
// lock is taken while quickshell loads instead, see "Locked from the start" below.
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

    // ---- Locked from the start (greetd autologin) ------------------------------------------------
    // The Hyprland autostart launches quickshell with QS_LOCK_AT_START=1 when greetd auto-logged in
    // (LOCK_ON_LOGIN=1). Then the lock is requested while quickshell loads, in the same pass that
    // creates the bars, so Hyprland goes from black straight to the lock screen (it hides everything
    // else as soon as a lock is requested). No fade-in: the lock content is fully drawn from its first
    // frame. (A fade from opacity 0 once left the screen black at boot: the animation never ran, so
    // the lock was up but invisible.)
    // Only once per quickshell process: `loaded` sees done = false on a fresh start, and the restored
    // true on hot reloads (values are restored before `loaded`, but after onCompleted).
    // Hyprland starts that session with the cursor invisible and keybinds off (empty "boot" submap,
    // ~/.config/hypr/modules/autostart.lua). Once the lock is secure the submap is reset (keybinds
    // stay blocked by the lock itself until unlocking; volume / brightness keep working) and the
    // marker file tells Hyprland's config not to do it again; the cursor is shown on the first mouse
    // movement over the lock screen, or at the latest on unlock.
    PersistentProperties {
        id: loginLock
        reloadableId: "loginLock"
        property bool done: false
        property bool releasePending: false   // lock not secure yet: submap reset + marker still to do
        property bool cursorHidden: false     // Hyprland cursor.invisible still on
        onLoaded: {
            if (!done && Quickshell.env("QS_LOCK_AT_START") === "1") {
                releasePending = true
                cursorHidden = true
                root.loginCover = 1
                coverFailsafe.start()
                root.lockNow()
            }
            done = true
        }
    }
    property point loginCursorStart: Qt.point(-1, -1)

    // Fade-in at login: the lock screen is always fully drawn; a black cover over it (LockSurface)
    // fades out once the lock is secure. If anything about the fade goes wrong, the lock screen is
    // right underneath: the fade is stepped by a plain Timer (not a QML animation, which once never
    // ran at boot and left the screen black), and coverFailsafe removes the cover outright.
    // Each step counts at most 33 ms of progress, so a busy moment pauses the fade instead of
    // skipping it; and the desktop behind the lock (bars, icons...) is only created once the fade is
    // done (finishCover), since creating it blocks this thread (it used to eat the whole fade).
    property real loginCover: 0          // opacity of the black cover, 1 -> 0
    property double coverProgress: 0     // ms of fade done
    property double coverLast: 0
    readonly property int coverDuration: 600
    function startCoverFade() {
        if (loginCover <= 0 || coverStep.running) return
        coverProgress = 0
        coverLast = Date.now()
        coverStep.start()
    }
    function finishCover() {
        coverStep.stop()
        coverFailsafe.stop()
        loginCover = 0
        desktopReleased = true           // login: now the desktop can load behind the lock
    }
    Timer {
        id: coverStep
        interval: 16
        repeat: true
        onTriggered: {
            const now = Date.now()
            root.coverProgress += Math.min(now - root.coverLast, 33)
            root.coverLast = now
            const t = Math.min(1, root.coverProgress / root.coverDuration)
            root.loginCover = Math.pow(1 - t, 3)            // ease-out cubic
            if (t >= 1) root.finishCover()
        }
    }
    Timer {
        id: coverFailsafe
        interval: 3000                    // from the lock request; the fade normally ends well before
        onTriggered: root.finishCover()
    }

    // Everything else in shell.qml (bars, desktop, frame...) waits for the lock at login
    // (holdDesktop): Hyprland keeps showing ordinary surfaces until the lock surfaces arrive, so
    // windows created alongside the lock flashed up before it. Decided while loading, so a hot
    // reload doesn't rebuild the bars: the marker file (written below once the lock is secure)
    // says the login lock already happened. Read synchronously (blockLoading).
    readonly property bool lockAtStart: Quickshell.env("QS_LOCK_AT_START") === "1"
    FileView {
        id: loginMarker
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/hypr-login-lock-done"
        blockLoading: true
        printErrors: false
    }
    property bool desktopReleased: false
    // this quickshell started at a greetd autologin and the login lock hasn't happened yet (fixed at
    // load: false again on hot reloads, the marker exists by then)
    readonly property bool loginStart: lockAtStart && loginMarker.text().trim() !== "done"
    readonly property bool holdDesktop: loginStart && !desktopReleased

    function releaseLoginInput() {
        if (loginCover <= 0) desktopReleased = true      // at login: after the fade (finishCover)
        if (!loginLock.releasePending) return
        loginLock.releasePending = false
        Quickshell.execDetached(["sh", "-c",
            "printf done > \"$XDG_RUNTIME_DIR/hypr-login-lock-done\"; hyprctl dispatch 'hl.dsp.submap(\"reset\")'"])
        parkLoginCursor()
    }

    // During boot the (invisible) cursor is parked in the bottom-right corner (hypr autostart), so
    // its flashes stay off screen. Once the lock is up it moves to the bottom centre, a bit above the
    // edge so the whole arrow shows there without covering the lock screen's content; still hidden
    // until the mouse moves. Pointer events right after the move are ignored (the move itself, or
    // the corner position arriving late, isn't the user moving the mouse).
    readonly property int loginCursorBottomGap: 32       // px from the bottom edge to the arrow's tip
    property double loginCursorIgnoreUntil: 0
    function parkLoginCursor() {
        const sc = Quickshell.screens[0]
        if (!sc) return
        const x = Math.round(sc.x + sc.width / 2)
        const y = Math.round(sc.y + sc.height - loginCursorBottomGap)
        loginCursorStart = Qt.point(-1, -1)
        loginCursorIgnoreUntil = Date.now() + 300
        Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.cursor.move({ x = ${x}, y = ${y} })`])
    }

    function showLoginCursor() {
        if (!loginLock.cursorHidden) return
        loginLock.cursorHidden = false
        Quickshell.execDetached(["hyprctl", "dispatch", "function() hl.config({ cursor = { invisible = false } }) end"])
    }

    // from LockSurface's HoverHandler: the first position seen is where the cursor already was
    // (the surface appearing under it); a move of a few px from there is a real movement
    function pointerMoved(p) {
        if (!loginLock.cursorHidden || !sessionLock.secure) return
        if (Date.now() < loginCursorIgnoreUntil) return
        if (loginCursorStart.x < 0) { loginCursorStart = p; return }
        if (Math.abs(p.x - loginCursorStart.x) + Math.abs(p.y - loginCursorStart.y) > 4) showLoginCursor()
    }
    // Lock right away, without the fade-in overlay (`qs ipc call lock lockNow`, and at login above).
    function lockNow() {
        if (sessionLock.locked) return
        pendingLock = false
        fadeInAnim.stop()
        fadeOutAnim.stop()
        unlocking = false
        password = ""
        failed = false
        busy = false
        fade = 1                         // as after a normal fade-in, so unlocking fades out the same way
        sessionLock.locked = true
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
        showLoginCursor()                // login lock: unlocked without touching the mouse
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
            if (secure) root.startCoverFade()                               // login lock: fade in from black
            if (secure) root.releaseLoginInput()                            // login lock: desktop + keybinds back
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
        function lockNow(): void { root.lockNow() }
        // true once the lock covers every screen (Hyprland autostart waits for it before the wallpaper)
        function isLocked(): bool { return sessionLock.secure }
        function suspend(): void { root.suspend() }
    }
}
