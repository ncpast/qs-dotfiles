import Quickshell
import QtQuick
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick
import Quickshell.Io

Item {
    id: root

    property var binds: []
    property var variables: ({})
    property bool loaded: false

    FileView {
        id: configFile
        path: Quickshell.env("HOME") + "/.config/hypr/hyprland.conf"
        watchChanges: true

        onLoaded: {
            var content = text()
            root.variables = parseVariables(content)
            root.binds = parseBinds(content, root.variables)
            root.loaded = true
        }
    }
    
    function stripComment(line) {
        var inQuotes = false
        for (var i = 0; i < line.length; i++) {
            var c = line[i]
            if (c === '"') inQuotes = !inQuotes
            if (c === '#' && !inQuotes) {
                return line.substring(0, i)
            }
        }
        return line
    }

    function parseVariables(content) {
        var vars = {}
        var lines = content.split("\n")
        var varRegex = /^\s*\$(\w+)\s*=\s*(.+?)\s*$/

        for (var i = 0; i < lines.length; i++) {
            var line = stripComment(lines[i])
            var match = line.match(varRegex)
            if (match) {
                vars[match[1]] = match[2].trim()
            }
        }
        return vars
    }

    function parseBinds(content, vars) {
        var result = []
        var lines = content.split("\n")
        var bindRegex = /^\s*bind\s*=\s*([^,]*),\s*([^,]*),\s*([^,]*)(?:,\s*(.*))?$/

        for (var i = 0; i < lines.length; i++) {
            var line = stripComment(lines[i])
            var match = line.match(bindRegex)
            if (match) {
                var mods = resolveVars(match[1].trim(), vars)
                var key = match[2].trim()
                var dispatcher = match[3].trim()
                var args = resolveVars((match[4] || "").trim(), vars)

                result.push({ mods: mods, key: key, dispatcher: dispatcher, args: args })
            }
        }
        return result
    }

    function resolveVars(str, vars) {
        // Replace every $name occurrence with its resolved value
        var result = str
        var varRegex = /\$(\w+)/g
        var match
        var seen = 0
        while ((match = varRegex.exec(result)) !== null && seen < 10) {
            var name = match[1]
            if (vars[name] !== undefined) {
                result = result.replace("$" + name, vars[name])
                varRegex.lastIndex = 0   // restart scan since string changed
            }
            seen++   // safety cap in case of unresolved/circular refs
        }
        return result
    }

    function shortcutFor(dispatcher, argsContains) {
        for (var i = 0; i < binds.length; i++) {
            var b = binds[i]
            if (b.dispatcher === dispatcher && b.args.indexOf(argsContains) !== -1) {
                return formatShortcut(b.mods, b.key)
            }
        }
        return ""
    }

    function formatShortcut(mods, key) {
        var modMap = { "SUPER": "⌘", "SHIFT": "󰘶", "CTRL": "⌃", "ALT": "⌥" }
        var parts = mods.split(" ").filter(m => m.length > 0)
        var formatted = parts.map(m => modMap[m] || m)
        formatted.push(key.toUpperCase())
        return formatted.join(" ")
    }
}