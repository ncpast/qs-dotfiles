pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Focus mode: "no distractions" look, in two flavours:
//   global  (menu bar → View → Focus Mode)             every workspace
//   local   (menu bar → Workspace → Focused Workspace)  only the workspaces you mark
// Hyprland side (no gaps, no rounding, solid borders) lives in
// ~/.config/hypr/modules/focusmode.lua; this singleton owns the state (session only) and
// tells Theme to go monotone while the focused workspace is in focus mode.
Singleton {
    id: root

    // global focus mode: every workspace
    property bool global: false
    // workspace id -> true, for every workspace in local focus mode
    property var workspaces: ({})

    readonly property int currentWorkspace: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1
    // true while looking at a focus-mode workspace: Theme goes monotone, the bar opaque black
    readonly property bool active: global || workspaces[currentWorkspace] === true

    // local state of a workspace (independent of global)
    function isFocused(id) { return workspaces[id] === true }

    function set(id, on) {
        var copy = Object.assign({}, workspaces)      // reassign so bindings re-evaluate
        if (on) copy[id] = true
        else delete copy[id]
        workspaces = copy
        hypr("FocusMode.set(" + id + ", " + (on ? "true" : "false") + ")")
    }

    function toggle(id) { set(id, !isFocused(id)) }
    function toggleCurrent() { if (currentWorkspace > 0) toggle(currentWorkspace) }

    function setGlobal(on) {
        global = on
        hypr("FocusMode.setGlobal(" + (on ? "true" : "false") + ")")
    }
    function toggleGlobal() { setGlobal(!global) }

    function hypr(lua) {
        Quickshell.execDetached(["hyprctl", "dispatch", "function() " + lua + " end"])
    }

    // Session only: start clean (a previous quickshell may have left rules switched on).
    Component.onCompleted: hypr("FocusMode.clear()")

    //   qs ipc call focus toggle        local: current workspace (e.g. for a keybind)
    //   qs ipc call focus toggleGlobal  global
    //   qs ipc call focus active        is the current workspace in focus mode?
    IpcHandler {
        target: "focus"
        function toggle(): void { root.toggleCurrent() }
        function toggleGlobal(): void { root.toggleGlobal() }
        function active(): bool { return root.active }
    }

    // A Hyprland config reload recreates its Lua state from scratch: re-apply ours.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "configreloaded") return
            if (root.global) root.hypr("FocusMode.setGlobal(true)")
            for (const id in root.workspaces)
                root.hypr("FocusMode.set(" + id + ", true)")
        }
    }
}
