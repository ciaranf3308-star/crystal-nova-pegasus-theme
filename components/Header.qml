import QtQuick 2.12
import "CrystalTheme.js" as T

// Top status bar: CRYSTAL brand left, clock + battery right, thin divider.
// Geometry measured from the approved hero (1280x960).
// Set fixedClock (e.g. "12:34") for deterministic previews/screenshots;
// when empty the live clock runs as normal.
Item {
    id: root
    height: T.headerH

    property string fontFamily: "monospace"
    property string fixedClock: ""

    Text {
        id: brand
        text: "CRYSTAL"
        x: T.brandX
        // glyph cap top lands at y44 (font ascent puts ink 10px below y)
        y: 34
        font.family: root.fontFamily
        font.pixelSize: T.fontTitlePx
        font.letterSpacing: T.titleLetterSpacing
        color: T.primaryInk
    }

    Text {
        id: clock
        // right edge at clockRightX, baseline aligned with the brand
        // (6px shaved off the margin for the glyph right side bearing)
        anchors.right: parent.right
        anchors.rightMargin: T.canvasW - T.clockRightX - 6
        y: brand.y
        font.family: root.fontFamily
        font.pixelSize: T.fontTitlePx
        font.letterSpacing: 2
        color: T.primaryInk
        // fixedClock pins the text for deterministic previews; the live
        // timer writes clockText so it never breaks this binding.
        property string clockText: "--:--"
        text: root.fixedClock !== "" ? root.fixedClock : clockText

        Timer {
            interval: 1000
            running: root.fixedClock === ""
            repeat: true
            triggeredOnStart: true
            onTriggered: parent.clockText = Qt.formatTime(new Date(), "hh:mm")
        }
    }

    BatteryIndicator {
        id: battery
        x: T.batteryX
        y: T.batteryY
        width: T.batteryW
        height: T.batteryH
    }

    Rectangle {
        x: T.margin
        width: parent.width - 2 * T.margin
        y: T.headerDividerY
        height: T.headerDividerH
        color: T.divider
    }
}
