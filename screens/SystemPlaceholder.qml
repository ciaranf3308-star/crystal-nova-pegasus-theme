import QtQuick 2.12

// TEMPORARY Phase 1 placeholder for the per-system library view.
// Exists only to prove A enters a system and B returns; the real
// library screen is designed in Phase 2.
Item {
    id: root

    property var collection: null
    property string fontFamily: "monospace"

    Rectangle {
        anchors.fill: parent
        color: "#262f3b"
    }

    Column {
        anchors.centerIn: parent
        spacing: 18

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: root.fontFamily
            font.bold: true
            font.pixelSize: 64
            font.letterSpacing: 4
            color: "#eadfc3"
            text: root.collection ? (root.collection.shortName || root.collection.name || "").toUpperCase() : ""
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: root.fontFamily
            font.pixelSize: 26
            color: "#a9c3d4"
            text: root.collection ? (root.collection.name || "") : ""
            visible: root.collection && root.collection.name !== (root.collection.shortName || "")
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: root.fontFamily
            font.pixelSize: 22
            font.letterSpacing: 2
            color: "#8ba3b5"
            text: {
                if (!root.collection || !root.collection.games) return ""
                var n = root.collection.games.count
                return n + (n === 1 ? " GAME IN LIBRARY" : " GAMES IN LIBRARY")
            }
        }
        Rectangle {
            width: 320
            height: 2
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#46566a"
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: root.fontFamily
            font.pixelSize: 20
            font.letterSpacing: 3
            color: "#8ba3b5"
            text: "SYSTEM LIBRARY VIEW -- PHASE 2"
        }
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 56
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 34
        font.family: root.fontFamily
        font.pixelSize: 22
        font.letterSpacing: 2
        color: "#8ba3b5"
        text: "B / BACK"
    }
}
