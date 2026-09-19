import QtQuick 2.12
import "CrystalTheme.js" as T

// Library footer (rebuilt 2026-09-19): a simple control strip.
// B BACK · Y INSPECT (GBA/PS2 only) · A PLAY. Nothing decorative,
// nothing that doesn't work. No center tabs, no collisions.
Item {
    id: root
    height: T.canvasH - T.libFooterDividerY

    property string fontFamily: "monospace"
    property bool showPlay: true
    property bool showInspect: false

    readonly property int rowY: 36

    // Hairline divider.
    Rectangle {
        x: T.margin
        width: parent.width - 2 * T.margin
        y: 0
        height: 2
        color: CrystalColors.divider
        opacity: 0.5
    }

    // B BACK (left)
    Row {
        x: 72; y: root.rowY
        spacing: 14
        Keycap {
            fontFamily: root.fontFamily
            circle: true
            text: "B"
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.family: root.fontFamily
            font.pixelSize: 24
            font.letterSpacing: 3
            color: CrystalColors.tileInk
            text: "BACK"
        }
    }

    // Y INSPECT (center-left, GBA/PS2 only)
    Row {
        x: 320; y: root.rowY
        spacing: 14
        visible: root.showInspect
        Keycap {
            fontFamily: root.fontFamily
            circle: true
            text: "Y"
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.family: root.fontFamily
            font.pixelSize: 24
            font.letterSpacing: 3
            color: CrystalColors.tileInk
            text: "INSPECT"
        }
    }

    // A PLAY (right)
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 72
        y: root.rowY
        spacing: 14
        visible: root.showPlay
        layoutDirection: Qt.RightToLeft
        Keycap {
            fontFamily: root.fontFamily
            circle: true
            text: "A"
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.family: root.fontFamily
            font.pixelSize: 24
            font.letterSpacing: 3
            color: CrystalColors.tileInk
            text: "PLAY"
        }
    }
}
