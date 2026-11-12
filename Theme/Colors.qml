pragma Singleton
import QtQuick

QtObject {
    readonly property color background:  '#16130b'   // hardest bg, bar base
    readonly property color background1: '#221f17'   // default bg
    readonly property color background2: '#38342b'   // raised surface

    readonly property color border_light: '#4b4639'  // subtle dividers
    readonly property color border:       '#979080'  // dividers

    readonly property color surface:      '#16130b'  // panels / popovers
    readonly property color text:         '#fde186'  // primary text
    readonly property color accent:       '#dfc56d'  // orange (unchanged)
}
