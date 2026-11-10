pragma Singleton
import QtQuick
import Quickshell.Services.UPower as UP

// Power profile state for the bar. Uses Quickshell's built-in power-profiles-daemon
// support (D-Bus inside quickshell), so there's no `gdbus monitor` child process that
// could be orphaned when quickshell is killed.
Item {
    id: root

    // cycle order; performance is skipped on machines that don't offer it
    readonly property var order: UP.PowerProfiles.hasPerformanceProfile
        ? [UP.PowerProfile.PowerSaver, UP.PowerProfile.Balanced, UP.PowerProfile.Performance]
        : [UP.PowerProfile.PowerSaver, UP.PowerProfile.Balanced]

    readonly property int profile: UP.PowerProfiles.profile
    readonly property int index: order.indexOf(profile)
    readonly property string powerProfile: {
        switch (profile) {
            case UP.PowerProfile.PowerSaver:  return "power-saver"
            case UP.PowerProfile.Balanced:    return "balanced"
            case UP.PowerProfile.Performance: return "performance"
            default:                          return ""
        }
    }

    readonly property string icon: {
        switch (powerProfile) {
            case "power-saver": return '󰌪'
            case "balanced":    return ''
            case "performance": return '󰓅'
            default:            return 'NA'
        }
    }

    function switchProfile() {
        UP.PowerProfiles.profile = order[(Math.max(index, 0) + 1) % order.length]
    }
}
