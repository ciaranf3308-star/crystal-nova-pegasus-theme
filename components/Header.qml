import QtQuick 2.12

// Top status bar: CRYSTAL brand left, clock + battery right, thin divider.
// Firmware feel: flat, pixel-clean, no decoration.
Item {
    id: root
    height: 92

    property color ink: "#dfe9f0"
    property color dim: "#8ba3b5"
    property color line: "#46566a"
    property string fontFamily: "monospace"

    Text {
        id: brand
        text: "CRYSTAL"
        anchors.left: parent.left
        anchors.leftMargin: 56
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -2
        font.family: root.fontFamily
        font.bold: true
        font.pixelSize: 36
        font.letterSpacing: 4
        color: root.ink
    }

    Text {
        id: clock
        anchors.right: battery.left
        anchors.rightMargin: 28
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -2
        font.family: root.fontFamily
        font.pixelSize: 30
        color: "#cfe0ea"
        text: "--:--"

        Timer {
            interval: 1000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: parent.text = Qt.formatTime(new Date(), "hh:mm")
        }
    }

    BatteryIndicator {
        id: battery
        anchors.right: parent.right
        anchors.rightMargin: 56
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -2
    }

    Rectangle {
        x: 56
        width: parent.width - 112
        y: parent.height - 2
        height: 2
        color: root.line
    }
}
