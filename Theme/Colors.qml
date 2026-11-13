pragma Singleton
import QtQuick

QtObject {
    readonly property color background:  '#121318'   // hardest bg, bar base
    readonly property color background1: '#1e1f25'   // default bg
    readonly property color background2: '#33343a'   // raised surface

    readonly property color border_light: '#45464f'  // subtle dividers
    readonly property color border:       '#8f909a'  // dividers

    readonly property color surface:      '#121318'  // panels / popovers
    readonly property color text:         '#dbe1ff'  // primary text
    readonly property color accent:       '#b3c5ff'  // orange (unchanged)
}
