pragma Singleton
import QtQuick

Item {
    property bool temp_is_active: false

    Timer {
        id: exitTimer
        interval: 100
        onTriggered: temp_is_active = false
    }

    function tempEntered() {
        exitTimer.stop()
        temp_is_active = true
    }

    function tempExited() {
        exitTimer.restart()
    }

    property string temp_displaying: ""
    property string power_profile: ""
}