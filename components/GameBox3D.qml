import QtQuick 2.12
import "CrystalTheme.js" as T
import "CrystalAssets.js" as CrystalAssets
import "SystemMeta.js" as SystemMeta
import "PhysicalMedia"
import "PhysicalMedia/MediaTemplates.js" as MT

// Library hero physical composition: the selected game's physical media,
// rendered large. GBA: 3D-ish game box (branded spine + cover front)
// with a cartridge in front. PS2: DVD case with cover art and the disc
// leaning beside it. Every other system: large framed cover art —
// never a placeholder card.
Item {
    id: root

    property var game: null
    property string shortName: ""
    property string fontFamily: "monospace"
    // Crystal index epoch: re-resolve artwork when the async index load
    // completes (same pattern as the grid tiles).
    property int artEpoch: 0

    readonly property string family: MT.familyFor(root.shortName)

    // All resolved crystal asset URLs for the game ("" when absent).
    property var det: {
        root.artEpoch;
        var d = CrystalAssets.details(root.game, root.shortName);
        return d ? d : { front: "", spine: "", back: "", media: "" };
    }
    property string frontArt: {
        var f = "";
        try { f = root.det.front || ""; } catch (e) { f = ""; }
        if (f !== "") return f;
        try { return CrystalAssets.tileFront(root.game, root.shortName); }
        catch (e2) { return ""; }
    }
    property string spineLabel: {
        var m = SystemMeta.metaFor(root.shortName);
        var s = (root.shortName || "").toString().trim().toUpperCase();
        if (root.family === "gba") return "GAME BOY ADVANCE";
        if (root.family === "ps2") return "PLAYSTATION 2";
        return s;
    }

    // ---- soft floor shadow shared by all compositions ----
    Rectangle {
        id: floorShadow
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height - 34
        width: parent.width * 0.72
        height: 26
        radius: 13
        color: "#000000"
        opacity: 0.45
    }

    // ================= GBA: box + cartridge =================
    Item {
        anchors.fill: parent
        visible: root.family === "gba"

        // scaled up to match hero's dominant box presence
        Item {
            x: 0; y: 5
            scale: 1.15
            transformOrigin: Item.TopLeft

        // box front (cover art)
        Rectangle {
            id: gbaBoxFront
            x: 50; y: 6
            width: 293; height: 330
            color: "#0e2236"
            border.width: 2
            border.color: "#2a4a6a"
            Image {
                anchors.fill: parent
                anchors.margins: 3
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                source: root.frontArt
                visible: source !== "" && status === Image.Ready
            }
            // top edge sliver: the 2.5D hint
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 10
                color: "#1d3a5c"
                opacity: 0.9
            }
        }
        // spine (left): branded strip with vertical system text
        Rectangle {
            x: 12; y: 6
            width: 38; height: 330
            color: "#0b1c30"
            border.width: 2
            border.color: "#2a4a6a"
            Rectangle {  // spine highlight edge
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: 3
                color: "#3a5f8a"
            }
            Text {
                anchors.centerIn: parent
                rotation: -90
                font.family: root.fontFamily
                font.pixelSize: 21
                font.letterSpacing: 6
                color: T.cream
                text: root.spineLabel
            }
        }

        // cartridge in front, overlapping the box's lower right
        Item {
            x: 305; y: 170
            width: 174; height: 180
            GbaCartridge {
                scale: 0.30
                transformOrigin: Item.TopLeft
                view: "front"
                labelArt: root.frontArt
                labelKind: root.frontArt !== "" ? "art" : "none"
                titleText: {
                    var t = "";
                    try { t = root.game ? (root.game.title || "") : ""; } catch (e) {}
                    return t;
                }
                fontFamily: root.fontFamily
            }
        }
        }  // scale wrapper
    }

    // ================= PS2: case + disc =================
    Item {
        anchors.fill: parent
        visible: root.family === "ps2"

        Item {
            x: 60; y: 0
            width: 245; height: 342
            Ps2Case {
                scale: 0.36
                transformOrigin: Item.TopLeft
                view: "front"
                frontArt: root.frontArt
                spineArt: {
                    var s = "";
                    try { s = root.det.spine || ""; } catch (e) {}
                    return s;
                }
                backArt: {
                    var b = "";
                    try { b = root.det.back || ""; } catch (e) {}
                    return b;
                }
                discArt: {
                    var m = "";
                    try { m = root.det.media || ""; } catch (e) {}
                    return m;
                }
                discKind: "art"
                titleText: {
                    var t = "";
                    try { t = root.game ? (root.game.title || "") : ""; } catch (e) {}
                    return t;
                }
                fontFamily: root.fontFamily
            }
        }
        // disc leaning against the case's right side
        Item {
            x: 315; y: 108
            width: 130; height: 130
            rotation: -8
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "#101c2c"
                border.width: 2
                border.color: "#3a5f8a"
                clip: true
                Image {
                    anchors.fill: parent
                    anchors.margins: 26
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true
                    source: {
                        var m = "";
                        try { m = root.det.media || ""; } catch (e) {}
                        return m !== "" ? m : root.frontArt;
                    }
                    visible: source !== "" && status === Image.Ready
                }
                // hub
                Rectangle {
                    anchors.centerIn: parent
                    width: 40; height: 40
                    radius: 20
                    color: "#0a1929"
                    border.width: 2
                    border.color: "#3a5f8a"
                }
            }
            // disc sheen arc
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: 14
                border.color: "#ffffff"
                opacity: 0.06
            }
        }
    }

    // ================= other systems: framed cover =================
    Item {
        anchors.fill: parent
        visible: root.family !== "gba" && root.family !== "ps2"
        Rectangle {
            anchors.centerIn: parent
            width: 300; height: 336
            color: "#0e2236"
            border.width: 2
            border.color: "#2a4a6a"
            Image {
                anchors.fill: parent
                anchors.margins: 4
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true
                source: root.frontArt
                visible: source !== "" && status === Image.Ready
            }
            GameFallbackArt {
                anchors.fill: parent
                anchors.margins: 4
                shortName: root.shortName
                title: {
                    var t = "";
                    try { t = root.game ? (root.game.title || "") : ""; } catch (e) {}
                    return t;
                }
                fontFamily: root.fontFamily
                visible: root.frontArt === ""
            }
        }
    }
}
