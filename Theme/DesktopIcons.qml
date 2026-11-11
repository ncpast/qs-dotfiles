pragma Singleton
import QtQuick

// Desktop icon configuration.
//
// The desktop is divided into an even `columns` x `rows` grid; each icon sits centered in
// its cell at grid position (x, y), where (0, 0) is the top-left cell.
//
// Item fields:
//   name     label shown under the icon
//   icon     icon theme name, window class / app id, or an absolute file path
//   command  program to launch (argv array)
//   x, y     grid cell (column, row)
//   glyphScale  optional, tinted mode only: < 1 shrinks the icon's symbol inside its tile, for
//               icons whose symbol runs off the tile's edges (default 1)
QtObject {
    readonly property int columns: 20
    readonly property int rows: 9

    readonly property int iconSize: 48*1.2
    readonly property int tileWidth: 96
    readonly property int tileHeight: 90

    readonly property var items: [
        { name: "Browser",  icon: "brave-browser",     command: ["brave"],      x: columns-1, y: 0 },
        { name: "Terminal", icon: "terminal",             command: ["kitty"],      x: columns-1, y: 1 },
        { name: "Code",     icon: "codium",            command: ["codium"],     x: columns-1, y: 2 },

        { name: "Discord",    icon: "discord", command: ["discord"],  x: columns-2, y: 0 },
        { name: "Spotify",    icon: "spotify", command: ["flatpak", "run", "com.spotify.Client"],  x: columns-2, y: 1 },
        { name: "Files",    icon: "nautilus", command: ["nautilus"],  x: columns-2, y: 2 },


        { name: "Steam",    icon: "steam", command: ["steam"],  x: columns-3, y: 0 },
        { name: "Telegram",    icon: "telegram", command: ["flatpak", "run", "org.telegram.desktop"],  x: columns-3, y: 1 },
        { name: "CS2",    icon: "counter-strike-2", command: ["steam", "steam://rungameid/730"],  x: columns-3, y: 2, glyphScale: 0.8 },
    ]
}
