pragma Singleton
import QtQuick
import Quickshell.Io
import "../Utils"

Item {
    id: root

    property int  volume: 0
    property bool muted: false

    readonly property string icon: {
        if (muted)        return ""
        if (volume == 0) return ""
        if (volume < 25)  return ""
        return ""
    }

    // pactl emits several "sink" events per volume step; coalesce them into one refresh.
    function updateAudioState() {
        updateDebounce.restart()
    }

    Timer {
        id: updateDebounce
        interval: 40
        onTriggered: {
            if (!volumeProc.running) volumeProc.running = true
            if (!muteStatusProc.running) muteStatusProc.running = true
        }
    }

    Process {
        id: subscribeProc
        command: ["pactl", "subscribe"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                if (data.includes("sink")) {
                    updateAudioState()
                }
            }
        }
    }

    Process {
        id: volumeProc
        command: ["pactl", "get-sink-volume", "@DEFAULT_SINK@"]

        stdout: SplitParser {
            onRead: data => {
                const match = data.match(/(\d+)%/)
                if (match) {
                    root.volume = parseInt(match[1])
                    //console.log('Volume:', root.volume)   
                }
            }
        }
    }

    Process {
        id: muteStatusProc
        command: ["pactl", "get-sink-mute", "@DEFAULT_SINK@"]

        stdout: SplitParser {
            onRead: data => {
                root.muted = data.includes("yes")
            }
        }
    }

    Process {
        id: toggleProc
        command: ["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"]
    }

    function toggleMute() {
        toggleProc.running = true
    }

    Component.onCompleted: updateAudioState()
}