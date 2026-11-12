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
    // A desktop entry whose Icon= is a file path (e.g. a custom icon set in
    // ~/.local/share/applications/*.desktop) uses that file, ahead of the aliases above: it's an
    // explicit choice. Icon theme names go through the theme as before.
    // Returns "" when nothing matches, so callers can try other names / their own icon.
    function lookup(name) {
        if (name === undefined || name === null || name === "") return ""
        if (name.startsWith("/")) return "file://" + name

        var custom = customIcon(name)
        if (custom !== "") return custom

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

    // File-path icon (Icon=/path/to/file) of a desktop entry matching name, or "".
    // Several entries can match (e.g. a distro's discord.desktop without an icon next to your own
    // com.discordapp.Discord.desktop), so every match is checked: heuristic lookup of the name and
    // of its alias, then any entry whose id (or the id's last part) / name / window class equals the name.
    function customIcon(name) {
        var apps = DesktopEntries.applications.values
        if (apps.length === 0) return ""
        var isFile = e => e && e.icon && e.icon.startsWith("/")
        var cands = [DesktopEntries.heuristicLookup(name)]
        if (aliases[name]) cands.push(DesktopEntries.heuristicLookup(aliases[name]))
        for (var i = 0; i < cands.length; i++)
            if (isFile(cands[i])) return "file://" + cands[i].icon
        var want = [_norm(_clean(name)), _norm(aliases[name])].filter(w => w !== "")
        for (var j = 0; j < apps.length; j++) {
            var e = apps[j]
            if (!isFile(e)) continue
            // reverse-DNS ids match on their last part too: "nautilus" -> org.gnome.Nautilus
            const idTail = (e.id || "").split(".").pop()
            if (want.indexOf(_norm(e.id)) !== -1 || want.indexOf(_norm(idTail)) !== -1
                    || want.indexOf(_norm(e.name)) !== -1 || want.indexOf(_norm(e.startupClass)) !== -1)
                return "file://" + e.icon
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
