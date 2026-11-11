pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick

// The wallpaper awww is showing on each output, as a screen-sized copy.
//
// Wallpapers can be huge (an 8K 16-bit PNG costs ~180 MB of RAM per load in the shell, vs ~20 MB
// at screen size), and the shell loads it twice (lock screen + desktop icon glass). So every
// wallpaper is scaled once, outside the shell, by vipsthumbnail, to the output's real pixel size,
// centre-cropped the same way awww shows it (resize "crop:center"), and cached in
// ~/.cache/quickshell/wallpaper/<output>-<hash>.png. Consumers use it with PreserveAspectCrop at
// screen size, which lines up 1:1. If scaling fails, the original file is used.
//
// Kept up to date without polling: awww writes each output's current wallpaper to
// ~/.cache/awww/<version>/<output>; that file is watched, and on change `awww query` gives the
// image path and the output's size / scale.
Singleton {
    id: root

    // output name -> "file://..." url of the screen-sized copy ("" until known)
    property var urls: ({})
    function urlFor(output) { return urls[output] ?? "" }

    readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/quickshell/wallpaper"

    property string version: ""
    Process {
        running: true
        command: ["awww", "--version"]       // "awww 0.12.1"
        stdout: StdioCollector {
            onStreamFinished: root.version = (text.match(/[0-9][0-9.]*/) || [""])[0]
        }
    }

    function setUrl(output, url) {
        var u = Object.assign({}, urls)
        u[output] = url
        urls = u
    }

    Variants {
        model: root.version !== "" ? Quickshell.screens : []

        Scope {
            id: out
            required property var modelData
            readonly property string name: modelData.name
            property string src: ""
            property string size: ""        // "WxH" in real pixels

            // changes whenever awww shows a new wallpaper on this output
            FileView {
                path: Quickshell.env("HOME") + "/.cache/awww/" + root.version + "/" + out.name
                watchChanges: true
                onFileChanged: reload()
                onLoaded: { query.running = false; query.running = true }
            }

            // ": eDP-1: 1920x1080, scale: 1.5, currently displaying: image: /path/to/wall.png"
            Process {
                id: query
                command: ["awww", "query"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        for (const line of text.split("\n")) {
                            // (lines may start with a namespace prefix, e.g. ": eDP-1: ...")
                            const m = line.match(/(?:^|\s)([^\s:]+): (\d+)x(\d+), scale: ([\d.]+),.*image: (.+)$/)
                            if (!m || m[1] !== out.name) continue
                            const s = parseFloat(m[4])
                            out.src = m[5].trim()
                            out.size = Math.round(m[2] * s) + "x" + Math.round(m[3] * s)
                            scale.running = false
                            scale.running = true
                            return
                        }
                    }
                }
            }

            // Prints the cached copy's path (made if missing), or nothing if scaling failed.
            // The name includes the source's mtime, so an edited file gets a fresh copy; older
            // copies for this output are removed.
            Process {
                id: scale
                command: ["sh", "-c", `
                    src=$1 size=$2 output=$3 dir=$4
                    hash=$(printf '%s %s %s' "$src" "$(stat -c %Y "$src" 2>/dev/null)" "$size" | md5sum | cut -c1-16)
                    dst="$dir/$output-$hash.png"
                    mkdir -p "$dir"
                    if [ ! -s "$dst" ]; then
                        vipsthumbnail "$src" --size "$size" --smartcrop centre \\
                            -o "$dst.tmp.png[bitdepth=8,compression=1]" 2>/dev/null \\
                            && mv "$dst.tmp.png" "$dst" || rm -f "$dst.tmp.png"
                    fi
                    [ -s "$dst" ] || exit 1
                    find "$dir" -maxdepth 1 -name "$output-*.png" ! -name "$output-$hash.png" -delete
                    printf '%s' "$dst"
                `, "sh", out.src, out.size, out.name, root.cacheDir]
                stdout: StdioCollector {
                    onStreamFinished: root.setUrl(out.name, "file://" + (text.trim() !== "" ? text.trim() : out.src))
                }
            }
        }
    }
}
