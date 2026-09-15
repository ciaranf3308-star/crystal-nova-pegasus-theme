import QtQuick 2.12
import "IconResolver.js" as IconResolver
import "CrystalTheme.js" as T

// Polished fallback when a game has no box art: system abbreviation,
// game title, and the production system icon on a dark Crystal card.
// Never a broken-image icon.
Item {
    id: root

    property string shortName: ""
    property string title: ""
    property string fontFamily: "monospace"

    Rectangle {
        anchors.fill: parent
        color: T.tileFill
        border.width: 2
        border.color: T.tileBorder
    }

    // production system icon, small and quiet at the top
    Image {
        width: 96
        height: 96
        anchors.horizontalCenter: parent.horizontalCenter
        y: 18
        fillMode: Image.PreserveAspectFit
        smooth: true
        source: IconResolver.iconFor(root.shortName, false)
        visible: source !== "" && status === Image.Ready
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 122
        width: parent.width - 24
        horizontalAlignment: Text.AlignHCenter
        font.family: root.fontFamily
        font.pixelSize: T.fallbackAbbrPx
        font.letterSpacing: 4
        color: T.primaryInk
        text: T.displayNameFor(root.shortName, "")
        elide: Text.ElideRight
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        width: parent.width - 24
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        maximumLineCount: 3
        wrapMode: Text.WordWrap
        elide: Text.ElideRight
        font.family: root.fontFamily
        font.pixelSize: T.fallbackTitlePx
        font.letterSpacing: 1
        color: T.tileInk
        text: (root.title || "UNTITLED").toUpperCase()
    }
}
