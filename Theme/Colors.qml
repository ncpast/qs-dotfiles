pragma Singleton
import QtQuick

QtObject {
    readonly property color background:  '#0f1512'   // hardest bg, bar base
    readonly property color background1: '#1b211e'   // default bg
    readonly property color background2: '#303632'   // raised surface

    readonly property color border_light: '#404944'  // subtle dividers
    readonly property color border:       '#8a938d'  // dividers

    readonly property color surface:      '#0f1512'  // panels / popovers
    readonly property color text:         '#a8f2cf'  // primary text
    readonly property color accent:       '#8cd5b3'  // orange (unchanged)
}
