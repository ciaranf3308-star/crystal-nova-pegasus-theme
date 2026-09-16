import QtQuick 2.12
import "MediaTemplates.js" as MT
import "../CrystalTheme.js" as T

// GBA cartridge: Crystal-owned shell template + game label texture.
//
// 2.5D is a static pose — a slight Y-axis tilt applied by PhysicalObject
// plus a layered drop shadow. No animation lives here: the tile contract
// is colour-only on browse, and Inspect drives view changes from above.
//
// view: "front" (label) | "back" (embossed moulding).
// Natural size 300x320 (MT.GBA); the parent scales to fit.
Item {
    id: root
    width: MT.GBA.w
    height: MT.GBA.h

    property string view: "front"
    property string labelArt: ""     // resolved label texture URL ("" = generated)
    property string titleText: ""   // for generated faces
    property string fontFamily: "monospace"
    property bool inserting: false   // launch transition: slides toward the slot

    // Inner slide wrapper: the parent centers this root with anchors,
    // which would override a y animation placed on root itself.
    Item {
        id: slide
        anchors.fill: parent
        y: root.inserting ? 170 : 0
        opacity: root.inserting ? 0 : 1
        Behavior on y { NumberAnimation { duration: 380; easing.type: Easing.InQuad } }
        Behavior on opacity { NumberAnimation { duration: 380 } }

    // ---- drop shadow: two stacked translucent slabs read as a soft
    // edge without needing QtGraphicalEffects (unavailable in Pegasus).
    Rectangle {
        x: 6; y: 16
        width: parent.width; height: parent.height
        radius: MT.GBA.bodyRadius
        color: "#000000"; opacity: 0.22
    }
    Rectangle {
        x: 3; y: 9
        width: parent.width; height: parent.height
        radius: MT.GBA.bodyRadius
        color: "#000000"; opacity: 0.22
    }

    // ---- shell ---------------------------------------------------------
    Rectangle {
        id: body
        anchors.fill: parent
        radius: MT.GBA.bodyRadius
        border.width: 2
        border.color: "#5f666e"
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#b2b8c0" }
            GradientStop { position: 0.45; color: "#9aa1a9" }
            GradientStop { position: 1.0; color: "#7e858d" }
        }
    }

    // top edge ridge (the cart's upper lip)
    Rectangle {
        x: 18; y: 10
        width: parent.width - 36; height: 8
        radius: 4
        color: "#c6ccd3"
        opacity: 0.85
    }

    // ---- front: label ----------------------------------------------------
    Item {
        id: labelZone
        x: MT.GBA.labelX; y: MT.GBA.labelY
        width: MT.GBA.labelW; height: MT.GBA.labelH
        visible: root.view === "front"

        // label well: recessed dark edge under the artwork
        Rectangle {
            anchors.fill: parent
            radius: 10
            color: "#3c4249"
        }
        Item {
            anchors.fill: parent
            anchors.margins: 3
            clip: true

            Rectangle {
                anchors.fill: parent
                radius: 7
                color: "#00000000"
            }

            Image {
                id: labelImg
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                source: root.labelArt
                visible: source !== "" && status === Image.Ready
            }

            // generated label: Crystal tokens, never a broken image
            Rectangle {
                anchors.fill: parent
                color: T.creamInk
                border.width: 2
                border.color: T.tileBorder
                visible: !labelImg.visible
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 26
                font.family: root.fontFamily
                font.pixelSize: 64
                font.letterSpacing: 4
                color: T.primaryInk
                text: MT.abbrFor(root.titleText)
                visible: !labelImg.visible
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 18
                width: parent.width - 24
                horizontalAlignment: Text.AlignHCenter
                font.family: root.fontFamily
                font.pixelSize: 20
                font.letterSpacing: 2
                color: T.tileInk
                elide: Text.ElideRight
                text: (root.titleText || "UNTITLED").toUpperCase()
                visible: !labelImg.visible
            }
        }

        // plastic gloss over the label: restrained, static
        Rectangle {
            anchors.fill: parent
            anchors.margins: 3
            radius: 7
            opacity: 0.10
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#ffffff" }
                GradientStop { position: 0.5; color: "#ffffff" }
                GradientStop { position: 0.51; color: "#ffffff00" }
                GradientStop { position: 1.0; color: "#ffffff00" }
            }
        }
    }

    // ---- back: embossed moulding -------------------------------------------
    Item {
        anchors.fill: parent
        visible: root.view === "back"

        Rectangle {
            x: 34; y: 40
            width: parent.width - 68; height: 150
            radius: 8
            color: "#000000"
            opacity: 0.14
        }
        // mould lines
        Repeater {
            model: 4
            Rectangle {
                x: 52; y: 66 + index * 30
                width: parent.width - 104; height: 3
                radius: 1
                color: "#6e747c"
                opacity: 0.8
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 196
            font.family: root.fontFamily
            font.pixelSize: 15
            font.letterSpacing: 3
            color: "#5f666e"
            text: "GAME BOY ADVANCE"
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 66
            width: parent.width - 60
            horizontalAlignment: Text.AlignHCenter
            font.family: root.fontFamily
            font.pixelSize: 16
            font.letterSpacing: 1
            color: "#5f666e"
            elide: Text.ElideRight
            text: (root.titleText || "UNTITLED").toUpperCase()
        }
    }

    // grip grooves along the bottom edge (both views)
    Repeater {
        model: 3
        Rectangle {
            x: 70; y: 272 + index * 12
            width: parent.width - 140; height: 4
            radius: 2
            color: "#5f666e"
            opacity: 0.75
        }
    }

    // shell sheen: one restrained diagonal highlight over the plastic
    Rectangle {
        anchors.fill: body
        radius: MT.GBA.bodyRadius
        opacity: 0.07
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#ffffff00" }
            GradientStop { position: 0.35; color: "#ffffff" }
            GradientStop { position: 0.55; color: "#ffffff00" }
            GradientStop { position: 1.0; color: "#ffffff00" }
        }
    }
    } // slide
}
