pragma Singleton
import QtQuick
import Quickshell.Io
import "../Utils"

Item {
    id: root

    property int cpu_temp: 0
    property int gpu_temp: 0
    // false until nvidia-smi gives a real reading, and again if it errors or reports 0 (no NVIDIA GPU /
    // driver, e.g. on an integrated GPU): the GPU sensor and its popup line are hidden meanwhile
    property bool gpu_available: false

    property string network_type: ""
    property string network_icon: "󰤮"
    property int network_strength: 0

    Process {
        id: updateGpuTempProc
        command: ["bash", "-c", "nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader"]

        // when it fails, nvidia-smi prints its error message on stdout, so only a number counts
        stdout: SplitParser {
            onRead: data => {
                const t = parseInt(data)
                root.gpu_available = !isNaN(t) && t > 0
                root.gpu_temp = root.gpu_available ? t : 0
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.gpu_available = false
                root.gpu_temp = 0
            }
        }
    }
    
    Process {
        id: updateCpuTempProc
        command: ["bash", "-c", "sensors | awk '/Core/ {sum += $3; count++} END {print sum/count}'"]

        stdout: SplitParser {
            onRead: data => {
                cpu_temp = Math.round(data)
                //console.log(cpu_temp)
            }
        }
    }

    Process {
        id: checkInternet
        command: ["bash", "-c", "~/.config/quickshell/scripts/checkInternet.sh"]

        stdout: SplitParser {
            onRead: data => {
                let parsedData = JSON.parse(data);
                const iconDict = {
                    "0": "󰤫",
                    "1": "󰤯",
                    "2": "󰤟",
                    "3": "󰤢",
                    "4": "󰤥",
                    "5": "󰤨"
                }

                network_type = parsedData.type;
                network_strength = parsedData.score == null ? 0 : parsedData.score; 
                
                switch(network_type) {
                    case "ethernet":
                        network_icon = "󰈀";
                        break;
                    case "wifi":
                        network_icon = iconDict[network_strength];
                        break;
                    default:
                        network_icon = "󰤮";
                        break;
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            updateGpuTempProc.running = true
            updateCpuTempProc.running = true
            checkInternet.running = true
        }
    }

    function updateTemp() {
        updateGpuTempProc.running = true
        updateCpuTempProc.running = true
            checkInternet.running = true
    }
}