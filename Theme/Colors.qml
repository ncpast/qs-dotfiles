pragma Singleton
import QtQuick

QtObject {
    readonly property color background:  '#18120b'   // hardest bg, bar base
    readonly property color background1: '#251f17'   // default bg
    readonly property color background2: '#3b342b'   // raised surface

    readonly property color border_light: '#4f4539'  // subtle dividers
    readonly property color border:       '#9c8f80'  // dividers

    readonly property color surface:      '#18120b'  // panels / popovers
    readonly property color text:         '#ffddb5'  // primary text
    readonly property color accent:       '#f5bc6f'  // orange (unchanged)
}
