import Quickshell
import QtQuick

// Runs the built-in display at 60 Hz while the power profile is power-saver, at its normal rate
// (120 Hz) otherwise. The monitor settings live in ~/.config/hypr/modules/monitor.lua, which also
// applies them when Hyprland's config loads; this re-applies them whenever the profile changes.
Scope {
    id: root

    readonly property bool saver: PowerProfiles.powerProfile === "power-saver"

    function apply() {
        Quickshell.execDetached(["hyprctl", "dispatch", 'function() require("modules.monitor").apply() end'])
    }

    onSaverChanged: apply()
    // started in power saver: make sure it's applied (the config may have loaded before the daemon was up)
    Component.onCompleted: if (saver) apply()
}
