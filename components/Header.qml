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
    // Library screens set this to e.g. "PLAY MORE GAMES"; the home
    // screen keeps it empty (plain CRYSTAL brand).
    property string subtitle: ""
    // Library screens set this to e.g. "CRYSTAL / GBA"; the home screen
    // keeps the plain "CRYSTAL" brand.
    property string title: "CRYSTAL"

    // Solid background — the reference hero has an opaque dark top bar;
    // without this the scenic backdrop bleeds through and washes out
    // the brand text (1-to-1 comparison 2026-09-18).
    Rectangle {
        anchors.fill: parent
        color: CrystalColors.headerShade
    }

    Text {
        id: brand
        text: root.title
        x: T.brandX
        // glyph cap top lands at y44 (font ascent puts ink 10px below y)
        y: 34
        font.family: root.fontFamily
        font.pixelSize: T.fontTitlePx
        font.letterSpacing: T.titleLetterSpacing
        color: CrystalColors.ink
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
        color: CrystalColors.ink
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

    // Centered subtitle with side rules (library screens). The rules run
    // from the brand to the battery, each ending in a small square node.
    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 30
        width: 760
        height: 44
        visible: root.subtitle !== ""

        Text {
            id: subText
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            font.family: root.fontFamily
            font.pixelSize: 24
            font.letterSpacing: 4
            color: CrystalColors.ink
            text: root.subtitle
        }
        Rectangle {  // left rule
            x: parent.width / 2 - 330
            y: 15
            width: 330 - subText.implicitWidth / 2 - 34
            height: 2
            color: CrystalColors.divider
            opacity: 0.55
        }
        Rectangle {  // left node
            x: parent.width / 2 - subText.implicitWidth / 2 - 30
            y: 11
            width: 8; height: 8
            color: CrystalColors.divider
            opacity: 0.8
        }
        Rectangle {  // right rule
            x: parent.width / 2 + subText.implicitWidth / 2 + 22
            y: 15
            width: 330 - subText.implicitWidth / 2 - 34
            height: 2
            color: CrystalColors.divider
            opacity: 0.55
        }
        Rectangle {  // right node
            x: parent.width / 2 + subText.implicitWidth / 2 + 22
            y: 11
            width: 8; height: 8
            color: CrystalColors.divider
            opacity: 0.8
        }
    }

    Rectangle {
        x: T.margin
        width: parent.width - 2 * T.margin
        y: T.headerDividerY
        height: T.headerDividerH
        color: CrystalColors.divider
    }
}
