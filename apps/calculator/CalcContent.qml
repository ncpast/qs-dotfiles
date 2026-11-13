pragma ComponentBehavior: Bound
import QtQuick
import "../../Theme"

Item {
    id: root

    property bool historyOpen: false

    readonly property int pad: 16
    readonly property int gap: 10
    readonly property real keySize: (width - 2 * pad - 3 * gap) / 4

    property alias engine: calc

    CalcEngine {
        id: calc
        onEvaluated: (equation, result) => historyModel.insert(0, { expr: equation, result: result })
    }

    focus: true
    Keys.onPressed: event => {
        const k = event.key
        const t = event.text
        let key = ""
        if (t >= "0" && t <= "9" && t.length === 1) key = t
        else if (t === "." || t === ",") key = "."
        else if (t === "+") key = "+"
        else if (t === "-") key = "−"
        else if (t === "*" || t === "x" || t === "X") key = "×"
        else if (t === "/") key = "÷"
        else if (t === "%") key = "%"
        else if (t === "=" || k === Qt.Key_Return || k === Qt.Key_Enter) key = "="
        else if (k === Qt.Key_Backspace) key = "⌫"
        else if (k === Qt.Key_Escape || k === Qt.Key_Delete) key = "AC"
        if (key === "") return
        calc.press(key)
        event.accepted = true
    }

    // Header
    Item {
        id: titleBar
        width: parent.width
        height: 60

        // history toggle
        CalcButton {
            id: historyButton
            x: parent.width - root.pad - width
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            height: 44
            rimShape: titleRimShape
            fill: Theme.background
            onClicked: root.historyOpen = !root.historyOpen

            // sidebar icon
            Item {
                anchors.centerIn: parent
                width: 20
                height: 16
                Rectangle {
                    anchors.fill: parent
                    radius: 3
                    color: "transparent"
                    border.width: 1.6
                    border.color: root.historyOpen ? Theme.accent : Theme.text
                }
                Rectangle {
                    x: 7
                    width: 1.6
                    height: parent.height
                    color: root.historyOpen ? Theme.accent : Theme.text
                }
            }
        }
    }

    // Display
    readonly property int displayMargin: 22
    readonly property real exprY: titleBar.height + 4
    readonly property real resultY: exprY + 26

    Text {
        anchors.right: parent.right
        anchors.rightMargin: root.displayMargin
        anchors.left: parent.left
        anchors.leftMargin: root.displayMargin
        y: root.exprY
        height: 26
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        text: calc.expr
        color: Theme.border
        font.family: "Inter"
        font.pixelSize: 20
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: 12
    }

    // The result keeps its size however long it gets: it grows out to the left and fades out into the
    // window background (the same colour as the window) over its left edge.
    Item {
        id: resultBox
        y: root.resultY
        width: root.width
        height: 64
        clip: true

        Text {
            anchors.right: parent.right
            anchors.rightMargin: root.displayMargin
            anchors.verticalCenter: parent.verticalCenter
            text: calc.display
            color: Theme.text
            font.family: "Inter"
            font.pixelSize: 56
            font.weight: Font.Normal
        }

        Rectangle {
            width: 90
            height: parent.height
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0;  color: Theme.background1 }
                GradientStop { position: 0.25; color: Theme.background1 }
                GradientStop { position: 1.0;  color: Qt.rgba(Theme.background1.r, Theme.background1.g, Theme.background1.b, 0) }
            }
        }
    }

    // Keypad
    // hidden key-sized circle: the glass rim shader of every key reads it (CalcButton)
    Rectangle {
        id: keyRimShape
        width: root.keySize
        height: root.keySize
        radius: width / 2
        visible: false
        layer.enabled: true
        layer.smooth: true
        layer.textureSize: Qt.size(width * 4, height * 4)
    }
    Rectangle {
        id: titleRimShape
        width: 44
        height: 44
        radius: 22
        visible: false
        layer.enabled: true
        layer.smooth: true
        layer.textureSize: Qt.size(width * 4, height * 4)
    }

    Grid {
        id: keypad
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.pad
        anchors.horizontalCenter: parent.horizontalCenter
        columns: 4
        spacing: root.gap

        Repeater {
            model: [
                "⌫", "AC", "%", "÷",
                "7", "8", "9", "×",
                "4", "5", "6", "−",
                "1", "2", "3", "+",
                "±", "0", ".", "="
            ]
            CalcButton {
                id: key
                required property string modelData
                readonly property bool isOp: "÷×−+=".indexOf(modelData) >= 0
                readonly property bool isFn: modelData === "⌫" || modelData === "AC" || modelData === "%"

                width: root.keySize
                height: root.keySize
                rimShape: keyRimShape
                fill: isOp ? Theme.accent : (isFn ? Qt.lighter(Theme.background2, Theme.bg_lighter) : Theme.background2)
                textColor: isOp ? Theme.background : Theme.text
                selected: isOp && modelData !== "=" && calc.pendingOp === modelData
                text: modelData === "±" ? "" : modelData
                fontSize: isOp ? 32 : (modelData === "AC" ? 24 : (modelData === "⌫" ? 26 : 28))
                fontWeight: isOp ? Font.Light : Font.Normal
                onClicked: calc.press(modelData)

                // +/− key: a small plus over a minus, split by a slash
                Item {
                    visible: key.modelData === "±"
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    Text {
                        x: 1; y: 0
                        text: "+"
                        color: Theme.text
                        font.family: "Inter"
                        font.pixelSize: 15
                    }
                    Text {
                        x: 14; y: 11
                        text: "−"
                        color: Theme.text
                        font.family: "Inter"
                        font.pixelSize: 15
                    }
                    Rectangle {
                        x: 13; y: 3
                        width: 1.6
                        height: 24
                        rotation: 40
                        antialiasing: true
                        color: Theme.text
                    }
                }
            }
        }
    }

    // History
    ListModel { id: historyModel }

    Rectangle {
        id: historyPanel
        anchors.top: titleBar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        color: Theme.background1
        opacity: root.historyOpen ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutQuad } }

        MouseArea { anchors.fill: parent }   // swallow clicks on the keys beneath

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 22
            y: 6
            text: "History"
            color: Theme.border
            font.family: "Inter"
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 22
            y: 6
            visible: historyModel.count > 0
            text: "Clear"
            color: Theme.accent
            font.family: "Inter"
            font.pixelSize: 13
            font.weight: Font.DemiBold
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: historyModel.clear()
            }
        }
        Text {
            anchors.centerIn: parent
            visible: historyModel.count === 0
            text: "No calculations yet"
            color: Theme.border
            font.family: "Inter"
            font.pixelSize: 14
        }

        ListView {
            anchors.fill: parent
            anchors.topMargin: 32
            anchors.bottomMargin: 8
            clip: true
            model: historyModel
            delegate: Item {
                id: entry
                required property string expr
                required property string result
                width: ListView.view.width
                height: 64

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    radius: Theme.button_radius
                    color: Theme.background2
                    opacity: entryMouse.containsMouse ? 0.7 : 0
                    Behavior on opacity { NumberAnimation { duration: 90 } }
                }
                Column {
                    anchors.right: parent.right
                    anchors.rightMargin: 22
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        anchors.right: parent.right
                        text: entry.expr
                        color: Theme.border
                        font.family: "Inter"
                        font.pixelSize: 14
                    }
                    Text {
                        anchors.right: parent.right
                        text: calc.group(entry.result)
                        color: Theme.text
                        font.family: "Inter"
                        font.pixelSize: 26
                    }
                }
                MouseArea {
                    id: entryMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        calc.load(entry.result)
                        root.historyOpen = false
                    }
                }
            }
        }
    }

    Component.onCompleted: forceActiveFocus()
}
