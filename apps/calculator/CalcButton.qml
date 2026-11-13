import QtQuick
import "../../Theme"

Item {
    id: root

    property string text: ""
    property color fill: Theme.background2
    property color textColor: Theme.text
    property int fontSize: 26
    property int fontWeight: Font.Normal
    property bool selected: false            // pending operator: inverted
    required property Item rimShape          // hidden, key-sized circle
    signal clicked()

    // custom glyphs (icons) go here instead of text
    default property alias glyph: glyphHolder.data

    scale: mouse.pressed ? 0.95 : (mouse.containsMouse ? 1.05 : 1)
    Behavior on scale { NumberAnimation { duration: 50 } }

    Rectangle {
        id: body
        anchors.fill: parent
        radius: width / 2
        color: root.selected ? Theme.background : root.fill
        Behavior on color { ColorAnimation { duration: Theme.colorChangeAnimDuration } }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "white"
            opacity: mouse.pressed ? -0.2 : (mouse.containsMouse ? 0.05 : 0)
            Behavior on opacity { NumberAnimation { duration: 90 } }
        }
    }

    ShaderEffect {
        anchors.fill: parent
        property variant source: root.rimShape
        property size texel: Qt.size(1 / Math.max(1, width), 1 / Math.max(1, height))
        property real rimPx: Theme.rim_width
        property real strength: Theme.rim_opacity
        fragmentShader: Qt.resolvedUrl("../../Widgets/shaders/glass_rim.frag.qsb")
        layer.enabled: true
        layer.smooth: true
        layer.mipmap: true
        layer.textureSize: Qt.size(width * 4, height * 4)
    }

    Item {
        id: glyphHolder
        anchors.fill: parent
    }

    Text {
        anchors.centerIn: parent
        visible: root.text !== ""
        text: root.text
        color: root.selected ? Theme.accent : root.textColor
        font.family: "Inter"
        font.pixelSize: root.fontSize
        font.weight: root.fontWeight
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
