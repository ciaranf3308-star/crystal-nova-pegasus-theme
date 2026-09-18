import QtQuick 2.12
import "CrystalTheme.js" as T

// Library footer (2026-09-18 hero): divider above the keycap row, then
// [B] BACK left, section tabs centred (GAMES · SYSTEMS · SETUP · PLAY),
// [A] PLAY right. GBA/PS2 libraries add [Y] INSPECT after BACK.
Item {
    id: root
    // spans from the footer divider to the bottom of the screen
    height: T.canvasH - T.libFooterDividerY

    property string fontFamily: "monospace"
    // Hidden on the empty-collection state — there is nothing to play.
    property bool showPlay: true
    // Physical-media Inspect prompt: GBA/PS2 libraries only.
    property bool showInspect: false

    readonly property int rowY: 38

    Rectangle {
        x: T.margin
        width: parent.width - 2 * T.margin
        y: 0
        height: T.footerDividerH
        color: CrystalColors.divider
        opacity: 0.7
    }

    Keycap {
        x: T.keycapL1X + 15
        y: root.rowY - 5
        fontFamily: root.fontFamily
        circle: true
        text: "B"
    }

    Text {
        x: T.recentX
        y: root.rowY + 6
        font.family: root.fontFamily
        font.pixelSize: T.fontFooterPx
        font.letterSpacing: T.footerLetterSpacing
        color: CrystalColors.tileInk
        text: "BACK"
    }

    Keycap {
        x: 375
        y: root.rowY - 5
        fontFamily: root.fontFamily
        circle: true
        text: "Y"
        visible: root.showInspect
    }

    Text {
        x: 455
        y: root.rowY + 6
        font.family: root.fontFamily
        font.pixelSize: T.fontFooterPx
        font.letterSpacing: T.footerLetterSpacing
        color: CrystalColors.tileInk
        text: "INSPECT"
        visible: root.showInspect
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.rowY + 8
        font.family: root.fontFamily
        font.pixelSize: 20
        font.letterSpacing: 2
        color: CrystalColors.dimInk
        text: "GAMES   \u00B7   SYSTEMS   \u00B7   SETUP   \u00B7   PLAY"
    }

    Keycap {
        x: parent.width - 207
        y: root.rowY - 5
        fontFamily: root.fontFamily
        circle: true
        text: "A"
        visible: root.showPlay
    }

    Text {
        x: parent.width - 128
        y: root.rowY + 6
        font.family: root.fontFamily
        font.pixelSize: T.fontFooterPx
        font.letterSpacing: T.footerLetterSpacing
        color: CrystalColors.tileInk
        text: "PLAY"
        visible: root.showPlay
    }
}
