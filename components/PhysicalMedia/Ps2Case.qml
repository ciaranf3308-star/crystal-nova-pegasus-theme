import QtQuick 2.12
import "MediaTemplates.js" as MT
import "../CrystalTheme.js" as T

// PS2 keep case: Crystal-owned case template + game face textures.
//
// Views: "front" (cover + spine sliver) | "spine" | "back" | "open"
// (tray + disc + swung cover). The open state is a 2.5D hinge illusion:
// the cover plane rotates around its left (spine) edge while an
// interior panel crossfades in past 90 degrees. openAmount animates
// automatically via a Behavior so parents just set view.
//
// lifting: launch-transition state — the disc scales toward the camera
// and fades while the tray dims; the parent then invokes game.launch().
//
// Natural size: 300x420 closed (MT.PS2), 600x420 open; the parent
// scales to fit. No animation lives on browse; all motion is driven
// from Inspect.
Item {
    id: root

    property string view: "front"
    property string frontArt: ""
    property string spineArt: ""
    property string backArt: ""
    property string discArt: ""
    property string titleText: ""
    property string fontFamily: "monospace"
    property bool lifting: false

    property real openAmount: view === "open" ? 1 : 0
    Behavior on openAmount { NumberAnimation { duration: 320; easing.type: Easing.InOutQuad } }

    width: view === "spine" ? 120 : (view === "open" ? 600 : 300)
    height: MT.PS2.caseH

    // Closed-case tilt is applied by PhysicalObject (tile vs inspect);
    // the hinge carries the open view.

    // ---- FRONT -------------------------------------------------------------
    Item {
        id: frontView
        anchors.fill: parent
        visible: root.view === "front"

        Rectangle { // shadow
            x: 8; y: 14; width: parent.width; height: parent.height
            color: "#000000"; opacity: 0.35
        }
        // spine sliver: explicit layered plane, not a texture stretch
        Rectangle {
            x: 0; y: 6; width: 26; height: parent.height - 6
            color: "#141c28"
            border.width: 1; border.color: T.tileBorder
        }
        Image {
            id: spineSliverImg
            x: 2; y: 10; width: 22; height: parent.height - 14
            fillMode: Image.PreserveAspectCrop
            smooth: true; asynchronous: true
            source: root.spineArt
            visible: source !== "" && status === Image.Ready
        }
        Text {
            x: 13; y: parent.height / 2
            width: parent.height - 40; height: 22
            rotation: -90
            transformOrigin: Item.Center
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: root.fontFamily
            font.pixelSize: 13
            font.letterSpacing: 2
            color: T.tileInk
            elide: Text.ElideRight
            text: MT.spineText(root.titleText)
            visible: !spineSliverImg.visible
        }

        // cover
        Item {
            x: 26; y: 0; width: parent.width - 26; height: parent.height
            Rectangle { // clear-sleeve plastic edge
                anchors.fill: parent
                color: "#dfe9f1"; opacity: 0.16
            }
            Image {
                id: frontImg
                anchors.fill: parent
                anchors.margins: MT.PS2.plasticEdge
                fillMode: Image.PreserveAspectCrop
                smooth: true; asynchronous: true
                source: root.frontArt
                visible: source !== "" && status === Image.Ready
            }
            // generated cover: Crystal tokens only
            Rectangle {
                anchors.fill: parent
                anchors.margins: MT.PS2.plasticEdge
                color: T.tileFill
                border.width: 2; border.color: T.tileBorder
                visible: !frontImg.visible
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 120
                font.family: root.fontFamily
                font.pixelSize: 72
                font.letterSpacing: 4
                color: T.primaryInk
                text: MT.abbrFor(root.titleText)
                visible: !frontImg.visible
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 44
                width: parent.width - 40
                horizontalAlignment: Text.AlignHCenter
                font.family: root.fontFamily
                font.pixelSize: 22
                font.letterSpacing: 2
                color: T.tileInk
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
                text: (root.titleText || "UNTITLED").toUpperCase()
                visible: !frontImg.visible
            }
            // sleeve highlight
            Rectangle {
                x: MT.PS2.plasticEdge; y: MT.PS2.plasticEdge
                width: 26; height: parent.height - 2 * MT.PS2.plasticEdge
                opacity: 0.10
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#ffffff" }
                    GradientStop { position: 1.0; color: "#ffffff00" }
                }
            }
        }
    }

    // ---- SPINE ---------------------------------------------------------------
    Item {
        anchors.fill: parent
        visible: root.view === "spine"

        Rectangle {
            x: 24; y: 8; width: parent.width - 24; height: parent.height
            color: "#000000"; opacity: 0.35
        }
        Rectangle {
            x: 16; width: 64; height: parent.height
            color: "#141c28"
            border.width: 2; border.color: T.tileBorder
        }
        Image {
            x: 18; width: 60; height: parent.height
            fillMode: Image.PreserveAspectCrop
            smooth: true; asynchronous: true
            source: root.spineArt
            visible: source !== "" && status === Image.Ready
        }
        Text {
            x: 48; y: parent.height / 2
            width: parent.height - 48; height: 30
            rotation: -90
            transformOrigin: Item.Center
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: root.fontFamily
            font.pixelSize: 20
            font.letterSpacing: 3
            color: T.tileInk
            elide: Text.ElideRight
            text: MT.spineText(root.titleText)
            visible: root.spineArt === ""
        }
        Rectangle { // steel rules top/bottom, Crystal frame language
            x: 16; y: 10; width: 64; height: 3; color: T.tileBorder
        }
        Rectangle {
            x: 16; y: parent.height - 13; width: 64; height: 3; color: T.tileBorder
        }
    }

    // ---- BACK ------------------------------------------------------------------
    Item {
        anchors.fill: parent
        visible: root.view === "back"

        Rectangle {
            x: 8; y: 14; width: parent.width; height: parent.height
            color: "#000000"; opacity: 0.35
        }
        Rectangle {
            anchors.fill: parent
            color: "#dfe9f1"; opacity: 0.12
        }
        Image {
            id: backImg
            anchors.fill: parent
            anchors.margins: MT.PS2.plasticEdge
            fillMode: Image.PreserveAspectCrop
            smooth: true; asynchronous: true
            source: root.backArt
            visible: source !== "" && status === Image.Ready
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: MT.PS2.plasticEdge
            color: T.tileFill
            border.width: 2; border.color: T.tileBorder
            visible: !backImg.visible
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 150
            font.family: root.fontFamily
            font.pixelSize: 60
            font.letterSpacing: 4
            color: T.primaryInk
            text: MT.abbrFor(root.titleText)
            visible: !backImg.visible
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 60
            width: parent.width - 48
            horizontalAlignment: Text.AlignHCenter
            font.family: root.fontFamily
            font.pixelSize: 20
            font.letterSpacing: 2
            color: T.tileInk
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
            text: (root.titleText || "UNTITLED").toUpperCase()
            visible: !backImg.visible
        }
    }

    // ---- OPEN --------------------------------------------------------------------
    Item {
        anchors.fill: parent
        visible: root.view === "open"

        // cover interior (crossfades in as the cover swings past 90 deg)
        Rectangle {
            x: 8; y: 0; width: 272; height: parent.height
            color: "#101823"
            border.width: 2; border.color: T.tileBorder
            opacity: root.openAmount < 0.45 ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 160 } }
        }
        Text {
            x: 8; width: 272
            y: parent.height / 2 - 40
            horizontalAlignment: Text.AlignHCenter
            font.family: root.fontFamily
            font.pixelSize: 18
            font.letterSpacing: 3
            color: T.tileInk
            opacity: 0.6
            text: "INSIDE COVER"
            visible: root.openAmount >= 0.45
        }

        // tray
        Item {
            x: 300; width: 300; height: parent.height
            Rectangle {
                x: 8; y: 14; width: parent.width; height: parent.height
                color: "#000000"; opacity: 0.35
            }
            Rectangle {
                anchors.fill: parent
                color: "#0d141d"
                border.width: 2; border.color: "#2a3646"
                opacity: root.lifting ? 0.45 : 1
                Behavior on opacity { NumberAnimation { duration: 300 } }
            }
            // disc hub ring
            Rectangle {
                x: parent.width / 2 - 34; y: MT.PS2.discY - 34
                width: 68; height: 68; radius: 34
                color: "#00000000"
                border.width: 3; border.color: "#2a3646"
            }

            // disc: Canvas so the art is truly circular
            Item {
                id: discLift
                x: parent.width / 2 - MT.PS2.discD / 2
                y: MT.PS2.discY - MT.PS2.discD / 2
                width: MT.PS2.discD; height: MT.PS2.discD
                transformOrigin: Item.Center
                scale: root.lifting ? 1.7 : 1
                opacity: root.lifting ? 0 : 1
                Behavior on scale { NumberAnimation { duration: 380; easing.type: Easing.InQuad } }
                Behavior on opacity { NumberAnimation { duration: 380 } }

                Image {
                    id: discArtImg
                    source: root.discArt
                    asynchronous: true
                    visible: false
                    onStatusChanged: discCanvas.requestPaint()
                }
                Canvas {
                    id: discCanvas
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        var c = MT.PS2.discD / 2;
                        // silver base
                        var g = ctx.createLinearGradient(0, 0, MT.PS2.discD, MT.PS2.discD);
                        g.addColorStop(0, "#eef1f5");
                        g.addColorStop(0.5, "#c6ccd5");
                        g.addColorStop(1, "#e2e7ed");
                        ctx.fillStyle = g;
                        ctx.beginPath();
                        ctx.arc(c, c, c, 0, Math.PI * 2);
                        ctx.fill();
                        var ready = discArtImg.status === Image.Ready;
                        if (ready) {
                            ctx.save();
                            ctx.beginPath();
                            ctx.arc(c, c, c, 0, Math.PI * 2);
                            ctx.clip();
                            ctx.drawImage(discArtImg, 0, 0, MT.PS2.discD, MT.PS2.discD);
                            ctx.restore();
                        } else {
                            // generated disc: data rings + Crystal abbr
                            ctx.strokeStyle = "rgba(90,99,109,0.35)";
                            ctx.lineWidth = 2;
                            var r;
                            for (r = 46; r < c - 6; r += 14) {
                                ctx.beginPath();
                                ctx.arc(c, c, r, 0, Math.PI * 2);
                                ctx.stroke();
                            }
                            ctx.fillStyle = "#5a636d";
                            ctx.font = "600 44px monospace";
                            ctx.textAlign = "center";
                            ctx.textBaseline = "middle";
                            ctx.fillText(MT.abbrFor(root.titleText), c, c - 24);
                            ctx.font = "20px monospace";
                            var t = (root.titleText || "UNTITLED").toUpperCase();
                            if (t.length > 22) t = t.substring(0, 22);
                            ctx.fillText(t, c, c + 22);
                        }
                        // hub hole + Crystal steel-blue hub ring
                        ctx.fillStyle = "#0d141d";
                        ctx.beginPath();
                        ctx.arc(c, c, 26, 0, Math.PI * 2);
                        ctx.fill();
                        ctx.strokeStyle = T.tileBorder;
                        ctx.lineWidth = 4;
                        ctx.beginPath();
                        ctx.arc(c, c, 26, 0, Math.PI * 2);
                        ctx.stroke();
                        // restrained shine: two translucent arcs
                        ctx.strokeStyle = "rgba(255,255,255,0.35)";
                        ctx.lineWidth = 18;
                        ctx.beginPath();
                        ctx.arc(c, c, c - 30, Math.PI * 1.15, Math.PI * 1.45);
                        ctx.stroke();
                        ctx.lineWidth = 10;
                        ctx.beginPath();
                        ctx.arc(c, c, c - 52, Math.PI * 1.2, Math.PI * 1.4);
                        ctx.stroke();
                    }
                    Component.onCompleted: requestPaint()
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: MT.PS2.discY + MT.PS2.discD / 2 + 26
                font.family: root.fontFamily
                font.pixelSize: 16
                font.letterSpacing: 3
                color: T.tileInk
                opacity: 0.55
                text: "COMPACT DISC"
            }
        }

        // swinging cover: rotates around the spine (left) edge
        Item {
            id: swingCover
            x: 300; width: 300; height: parent.height
            visible: root.openAmount < 0.55
            transform: Rotation {
                axis { x: 0; y: 1; z: 0 }
                angle: -150 * root.openAmount
                origin.x: 0
                origin.y: MT.PS2.caseH / 2
            }
            Rectangle {
                anchors.fill: parent
                color: "#dfe9f1"; opacity: 0.16
            }
            Image {
                anchors.fill: parent
                anchors.margins: MT.PS2.plasticEdge
                fillMode: Image.PreserveAspectCrop
                smooth: true; asynchronous: true
                source: root.frontArt
                visible: source !== "" && status === Image.Ready
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: MT.PS2.plasticEdge
                color: T.tileFill
                border.width: 2; border.color: T.tileBorder
                visible: root.frontArt === ""
            }
        }
    }

}
