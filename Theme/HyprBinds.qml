import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Looks shortcuts up by bind description, using `hyprctl binds -j`.
// In input.lua: hl.bind("SUPER + Q", ..., { description = "terminal" })
// In QML:       shortcuts.shortcutFor("terminal")  ->  "⌘ Q"
Item {
    id: root

    // description -> { mods, key }
    property var byDescription: ({})
    property bool loaded: false

    Process {
        id: bindsProc
        command: ["hyprctl", "binds", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.byDescription = root.parseBinds(JSON.parse(text))
                    root.loaded = true
                } catch (e) {
                    console.warn("Shortcuts: failed to parse hyprctl output:", e)
                }
            }
        }
    }

    // Refresh whenever Hyprland reloads its config
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded") bindsProc.running = true
        }
    }

    Component.onCompleted: bindsProc.running = true

    function modsFromMask(mask) {
        var names = []
        if (mask & 64) names.push("SUPER")
        if (mask & 4)  names.push("CTRL")
        if (mask & 8)  names.push("ALT")
        if (mask & 1)  names.push("SHIFT")
        return names.join(" ")
    }

    function parseBinds(json) {
        var map = {}
        json.forEach(b => {
            if (b.has_description && b.description)
                map[b.description] = { mods: modsFromMask(b.modmask), key: b.key }
        })
        return map
    }

    function shortcutFor(description) {
        var b = byDescription[description]
        return b ? formatShortcut(b.mods, b.key) : ""
    }

    function formatShortcut(mods, key) {
        var modMap = { "SUPER": "⌘", "SHIFT": "󰘶 ", "CTRL": "⌃", "ALT": "⌥" }
        var keyMap = { "ESCAPE": "Esc" }

        var parts = mods.split(" ").filter(m => m.length > 0)
        var formatted = parts.map(m => modMap[m] || m)

        var k = key.toUpperCase()
        formatted.push(keyMap[k] || k)
        return formatted.join(" ")
    }
}
