import QtQuick 2.12
import "MediaTemplates.js" as MT

// GbaCartridge — thin compositor over authored SVG templates.
//
// The cartridge shell is NEVER drawn here: it comes from
// assets/physical/gba/*.svg (original Crystal illustration). QML only
// layers game artwork into the template's transparent label window and
// adds small dynamic overlays (sheen pulse, launch insertion).
//
// view: "front" | "back"
// labelKind: "scan" (real cart art, shown as-is) | "art" (cover art is
//   source material for a deliberate Crystal label composition) |
//   "none" (designed fallback sticker — never a placeholder card)
Item {
    id: root
    implicitWidth: MT.GBA.w
    implicitHeight: MT.GBA.h

    property string view: "front"
    property string labelArt: ""
    property string labelKind: "none"
    property string titleText: ""
    property string fontFamily: "monospace"
    property bool inserting: false   // GBA launch: slide into the slot

    readonly property string assetBase: "../../assets/physical/gba/"

    // restrained view-change settle: a 140ms dip, never a spin
    NumberAnimation {
        id: viewDip
        target: root; property: "opacity"
        from: 0.55; to: 1; duration: 140
    }
    onViewChanged: { viewDip.restart(); sheenPulse.restart() }

    // sheen breathes once per view change (parallax hint, then rests)
    NumberAnimation {
        id: sheenPulse
        target: sheen; property: "opacity"
        from: 0; to: 0.65; duration: 420
        easing.type: Easing.OutQuad
    }

    // launch insertion: the cart slides down toward the Crystal slot.
    // The shift lives on an inner wrapper — the root is anchored by its
    // parent, so it must not set y itself. The shadow stays put.
    Item {
        id: cartBody
        anchors.fill: parent
        y: root.inserting ? 170 : 0
        Behavior on y {
            NumberAnimation { duration: 380; easing.type: Easing.InQuad }
        }

    // ---- soft shadow (authored, under everything) ----
    Image {
        source: root.assetBase + "shadow.svg"
        width: 700; height: 240
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height - 128
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: true
    }

    // ---- FRONT ----
    Item {
        id: frontView
        anchors.fill: parent
        visible: root.view !== "back"

        // game label artwork, clipped to the label well; the shell
        // template draws the recess AROUND this window (QML layering,
        // never an SVG mask)
        Rectangle {
            x: MT.GBA.labelX; y: MT.GBA.labelY
            width: MT.GBA.labelW; height: MT.GBA.labelH
            radius: 10
            clip: true
            color: "#7ba3cc"   // well backing: visible only if art fails

            // "scan": genuine cartridge artwork, shown as-is
            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                source: root.labelKind === "scan" ? root.labelArt : ""
                visible: source !== "" && status === Image.Ready
            }

            // "art": cover art as SOURCE MATERIAL for a deliberate
            // Crystal sticker composition — treated, never a blind crop
            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                opacity: 0.92
                source: root.labelKind === "art" ? root.labelArt : ""
                visible: source !== "" && status === Image.Ready
            }

            // "none": designed fallback sticker face
            Rectangle {
                anchors.fill: parent
                visible: root.labelKind === "none"
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#b9d4ea" }
                    GradientStop { position: 1.0; color: "#7ba3cc" }
                }
            }
            // sticker treatment over art-sourced or fallback labels
            // (real scans stay untouched above)
            Item {
                anchors.fill: parent
                visible: root.labelKind !== "scan"
                // micro brand pill
                Rectangle {
                    x: 16; y: 14; width: 118; height: 26
                    radius: 13
                    color: "#0e2236"
                    opacity: 0.92
                    Text {
                        anchors.centerIn: parent
                        font.family: root.fontFamily
                        font.pixelSize: 13
                        font.letterSpacing: 3
                        color: "#7ba7d9"
                        text: "CRYSTAL"
                    }
                }
                // title band
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 64
                    color: "#0c1c30"
                    opacity: 0.94
                }
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 64
                    height: 3
                    color: "#7ba7d9"
                }
                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    anchors.bottomMargin: 14
                    height: 36
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    font.family: root.fontFamily
                    font.pixelSize: 24
                    font.letterSpacing: 3
                    color: "#d7e3ec"
                    text: root.titleText.toUpperCase()
                }
            }
        }

        // authored shell: draws the cartridge AROUND the label window
        Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            source: root.assetBase + "shell-front.svg"
        }
        // crisp frame ring at the art/shell boundary
        Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            source: root.assetBase + "label-frame.svg"
        }
        // animated sheen overlay
        Image {
            id: sheen
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            opacity: 0
            source: root.assetBase + "sheen.svg"
        }
    }

    // ---- BACK ----
    Item {
        anchors.fill: parent
        visible: root.view === "back"
        Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            source: root.assetBase + "shell-back.svg"
        }
        Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            opacity: 0.5
            source: root.assetBase + "sheen.svg"
        }
    }
    } // cartBody

    Component.onCompleted: sheenPulse.restart()
}
