import QtQuick 2.12

// Small transient status line (e.g. "RECENT -- PHASE 2").
// Only ever appears in response to a button press; the resting screen
// stays uncluttered.
Text {
    id: root

    property string fontFamily: "monospace"

    font.family: root.fontFamily
    font.pixelSize: 22
    font.letterSpacing: 2
    color: "#8ba3b5"
    opacity: 0

    Timer {
        id: hideTimer
        interval: 1400
        onTriggered: root.opacity = 0
    }

    Behavior on opacity { NumberAnimation { duration: 250 } }

    function show(msg) {
        text = msg
        hideTimer.restart()
        opacity = 1
    }
}
