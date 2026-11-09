pragma Singleton
import Quickshell

// Resolves a window class / app id / icon name / file path to something an Image can load.
Singleton {
    // Window classes whose icon name differs from the class / has no desktop entry match.
    // Overrides take priority over the desktop entry's own icon. Add yours here, e.g. "org.gnome.Nautilus": "folder"
    readonly property var aliases: ({
        "brave-browser": "brave-desktop",
        "codium": "vscodium",
        "code": "vscode",
        "kitty": "terminal",
        "cs2": "counter-strike-2"
    })

    // Reading applications.values makes callers re-evaluate once desktop entries load
    // (heuristicLookup alone isn't reactive, which left some icons stuck on the fallback).
    // Returns "" when nothing matches, so callers can try other names / their own icon.
    function lookup(name) {
        if (name === undefined || name === null || name === "") return ""
        if (name.startsWith("/")) return "file://" + name

        var loaded = DesktopEntries.applications.values.length
        var entry = loaded > 0 ? DesktopEntries.heuristicLookup(name) : null
        var names = []
        if (aliases[name]) names.push(aliases[name])      // explicit overrides win
        if (entry && entry.icon) names.push(entry.icon)
        names.push(name, name.toLowerCase())
        for (var i = 0; i < names.length; i++) {
            var path = Quickshell.iconPath(names[i], true)
            if (path !== "") return path
        }
        return ""
    }

    function resolve(name) {
        return lookup(name) || Quickshell.iconPath("application-x-executable", true)
    }

    // ---- Names -----------------------------------------------------------------

    function _norm(str) { return (str || "").toLowerCase().replace(/[^a-z0-9]/g, "") }

    // Tray ids are often ugly ("discord_status_icon_1", "chrome_status_icon_2"):
    // strip the generic suffixes to leave the app's own name.
    function _clean(str) {
        return (str || "")
            .replace(/[_-]?(status[_-]?icon|tray[_-]?icon|tray|indicator)[_-]?\d*$/i, "")
            .replace(/[_-]\d+$/, "")
    }

    // Finds the desktop entry for a tray id / title / window class, or null.
    function entryFor(name) {
        if (!name) return null
        var apps = DesktopEntries.applications.values
        if (apps.length === 0) return null

        var clean = _clean(name)
        var direct = DesktopEntries.heuristicLookup(clean) || DesktopEntries.heuristicLookup(name)
        if (direct) return direct

        var want = _norm(clean)
        if (want === "") return null
        for (var i = 0; i < apps.length; i++) {
            var e = apps[i]
            if (_norm(e.id) === want || _norm(e.name) === want || _norm(e.startupClass) === want)
                return e
        }
        return null
    }

    // Human-readable program name for a tray item, e.g. "Telegram Desktop", "Discord".
    function displayName(id, title) {
        var e = entryFor(id) || entryFor(title)
        if (e && e.name) return e.name

        var t = _clean(title || id)
            .replace(/([a-z])([A-Z])/g, "$1 $2")     // TelegramDesktop -> Telegram Desktop
            .replace(/[_-]+/g, " ")
            .trim()
        return t.length > 0 ? t[0].toUpperCase() + t.slice(1) : (id || "")
    }
}
