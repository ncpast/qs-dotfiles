import Quickshell
import Quickshell.Io
import QtQuick
import "../Theme"

// Notifies (with its own sound) when a USB device is plugged in or removed, by watching
// udev events. No root / udev rule needed: the same events a rule would see are readable
// with `udevadm monitor`, and the notification goes out as the logged-in user.
Scope {
    id: root

    readonly property string appName: "USB Devices"   // Notifications.qml skips its default sound for this

    property var block: ({})
    property var names: ({})      // DEVPATH -> device name, filled on "add"

    Process {
        command: ["stdbuf", "-oL", "udevadm", "monitor", "--udev", "--subsystem-match=usb", "--property"]
        running: true
        stdout: SplitParser {
            onRead: raw => {
                // the blank line between events arrives glued to the next header ("\nUDEV ..."),
                // so trim before looking for the header
                var line = raw.trim()
                if (line.startsWith("UDEV ") || line.startsWith("KERNEL")) {
                    root.flush()
                    root.block = {}
                    return
                }
                var i = line.indexOf("=")
                if (i > 0) root.block[line.slice(0, i)] = line.slice(i + 1)
                done.restart()      // the last block of a burst has no terminator: flush when it goes quiet
            }
        }
    }

    Timer { id: done; interval: 150; onTriggered: { root.flush(); root.block = {} } }

    function flush() {
        var b = block
        if (b.SUBSYSTEM !== "usb" || b.DEVTYPE !== "usb_device") return
        if (b.ACTION !== "add" && b.ACTION !== "remove") return
        if ((b.TYPE || "").startsWith("9/")) return          // hubs

        function clean(s) { return (s || "").replace(/_/g, " ").trim() }
        var vendor = clean(b.ID_VENDOR_FROM_DATABASE || b.ID_VENDOR)
        var model = clean(b.ID_MODEL_FROM_DATABASE || b.ID_MODEL)
        var name = (vendor + " " + model).trim()

        // udev drops the model/vendor info from "remove" events, so remember the name from
        // when the device was added and reuse it on unplug.
        var added = b.ACTION === "add"
        if (added && name !== "") names[b.DEVPATH] = name
        if (!added) {
            name = names[b.DEVPATH] || name
            delete names[b.DEVPATH]
        }
        if (name === "") name = "USB device " + (b.PRODUCT || "")

        Quickshell.execDetached(["notify-send", "-a", appName, "-i", "drive-removable-media-usb",
            added ? "Device connected" : "Device disconnected", name])
        Quickshell.execDetached(["paplay",
            `/usr/share/sounds/${Theme.sound_theme}/stereo/${added ? "device-added" : "device-removed"}.oga`])
    }
}
