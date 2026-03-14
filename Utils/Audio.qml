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

    function updateAudioState() {
        volumeProc.running = true
        muteProc.running = true
        muteStatusProc.running = true
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
        id: muteProc
        command: ["pactl", "get-sink-mute", "@DEFAULT_SINK@"]

        stdout: SplitParser {
            onRead: data => {
                root.muted = data.includes("yes")
                //console.log(root.muted)
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