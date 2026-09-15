import QtQuick 2.12

// Bottom bar: thin divider, L1/RECENT left, R1/FAVOURITES right.
// A quiet page indicator appears in the centre only when the grid spans
// more than one page.
Item {
    id: root
    height: 88

    property color dim: "#8ba3b5"
    property color line: "#46566a"
    property string fontFamily: "monospace"
    property int page: 0
    property int pageCount: 1

    Rectangle {
        x: 56
        width: parent.width - 112
        y: 0
        height: 2
        color: root.line
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 56
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 2
        font.family: root.fontFamily
        font.pixelSize: 22
        font.letterSpacing: 2
        color: root.dim
        text: "L1 / RECENT"
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 56
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 2
        font.family: root.fontFamily
        font.pixelSize: 22
        font.letterSpacing: 2
        color: root.dim
        text: "R1 / FAVOURITES"
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 2
        font.family: root.fontFamily
        font.pixelSize: 20
        color: root.dim
        opacity: 0.8
        visible: root.pageCount > 1
        text: (root.page + 1) + " / " + root.pageCount
    }
}
