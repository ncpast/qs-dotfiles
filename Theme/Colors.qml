pragma Singleton
import QtQuick

QtObject {
    readonly property color background:  '#14140c'   // hardest bg, bar base
    readonly property color background1: '#202018'   // default bg
    readonly property color background2: '#36352c'   // raised surface

    readonly property color border_light: '#48473a'  // subtle dividers
    readonly property color border:       '#939182'  // dividers

    readonly property color surface:      '#14140c'  // panels / popovers
    readonly property color text:         '#e8e78f'  // primary text
    readonly property color accent:       '#cbcb76'  // orange (unchanged)
}
