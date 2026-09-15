import QtQuick 2.12
import "CrystalTheme.js" as T

// Library footer: same divider/keycap geometry as the Phase 1.7 home
// footer. Left: [B] BACK. Right: [A] PLAY. A quiet page indicator sits
// centred, visible only when the library spans more than one page.
Item {
    id: root
    // spans from the footer divider to the bottom of the screen
    height: T.canvasH - T.footerDividerY

    property string fontFamily: "monospace"
    property int page: 0
    property int pageCount: 1
    // Hidden on the empty-collection state — there is nothing to play.
    property bool showPlay: true

    Rectangle {
        x: T.margin
        width: parent.width - 2 * T.margin
        y: 0
        height: T.footerDividerH
        color: T.divider
    }

    Keycap {
        x: T.keycapL1X
        y: T.keycapY
        fontFamily: root.fontFamily
        text: "B"
    }

    Text {
        x: T.recentX
        y: T.keycapY
        font.family: root.fontFamily
        font.pixelSize: T.fontFooterPx
        font.letterSpacing: T.footerLetterSpacing
        color: T.tileInk
        text: "BACK"
    }

    Keycap {
        x: T.keycapR1X
        y: T.keycapY
        fontFamily: root.fontFamily
        text: "A"
        visible: root.showPlay
    }

    Text {
        x: T.favouritesX
        y: T.keycapY
        font.family: root.fontFamily
        font.pixelSize: T.fontFooterPx
        font.letterSpacing: T.footerLetterSpacing
        color: T.tileInk
        text: "PLAY"
        visible: root.showPlay
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: T.keycapY
        font.family: root.fontFamily
        font.pixelSize: T.fontFooterPx - 8
        color: T.tileInk
        opacity: 0.7
        visible: root.pageCount > 1
        text: (root.page + 1) + " / " + root.pageCount
    }
}
