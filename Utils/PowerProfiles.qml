pragma Singleton
import QtQuick
import Quickshell.Io
import "../Utils"

Item {
    id: root

    readonly property var profiles: {
        "power-saver": 0,
        "balanced":    1,
        "performance": 2
    }
    property int index: 2;
    property string powerProfile: '';
    property string bufferProfile: '';

    readonly property string icon: {
        if (powerProfile != bufferProfile) return '';

        switch(powerProfile) {
            case 'power-saver':
                return '󰌪';
            case 'balanced':
                return '';
            case 'performance':
                return '󰓅';
            default:
                return 'NA';
        }
    }
    
    function switchProfile() {
        const nextIndex = (index + 1) % 3
        const nextProfile = Object.keys(profiles).find(key => profiles[key] === nextIndex)
        index = nextIndex
        bufferProfile = nextProfile
        writeProfile.running = true
    }

    Process {
        id: writeProfile
        command: ["powerprofilesctl", "set", bufferProfile]
    }

    Process {
        id: update
        command: ["powerprofilesctl", "get"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                powerProfile = data;
                bufferProfile = powerProfile;
                index = profiles[data];
            }
        }
    }

    Process {
        id: monitor
        command: [
            "gdbus", "monitor",
            "--system",
            "--dest", "net.hadess.PowerProfiles",
            "--object-path", "/net/hadess/PowerProfiles"
        ]
        running: true

        stdout: SplitParser {
            onRead: data => {
                if (!data.includes("ActiveProfile")) return
                const match = data.match(/'ActiveProfile':\s*<'([^']+)'>/)
                //console.log("match:", match ? match[1] : "no match")

                powerProfile = match[1];
                index = profiles[powerProfile];
            }
        }
    }
}