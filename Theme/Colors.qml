pragma Singleton
import QtQuick

QtObject {
    readonly property color background:  '#19120c'   // hardest bg, bar base
    readonly property color background1: '#261e18'   // default bg
    readonly property color background2: '#3c332c'   // raised surface

    readonly property color border_light: '#51443a'  // subtle dividers
    readonly property color border:       '#9e8e82'  // dividers

    readonly property color surface:      '#19120c'  // panels / popovers
    readonly property color text:         '#ffdcc0'  // primary text
    readonly property color accent:       '#feb877'  // orange (unchanged)
}
