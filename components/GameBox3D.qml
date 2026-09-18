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

        // Warm glow washing the scene where the box stands.
        Image {
            x: 20; y: 10
            width: 480; height: 340
            source: "../assets/hero/warm-glow.svg"
            smooth: true
            asynchronous: true
            opacity: 0.85
        }

        // Box with 2D fake-3D depth: the front has a perspective skew
        // and the spine/top are drawn as receding parallelograms.
        // (Nested Qt 3D rotations do not compose reliably.)
        Item {
            id: gbaTilt
            anchors.fill: parent

        Item {
            id: box3d
            x: 60; y: 10
            scale: 1.42
            transformOrigin: Item.TopLeft

            // front face: cover art. The box depth comes from the
            // spine/top parallelograms; the front stays a clean rectangle.
            Rectangle {
                id: gbaBoxFront
                width: 260; height: 290
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
            }
            // spine: left side face as a 2D parallelogram receding into
            // the distance (fake 3D — nested 3D Rotation does not render).
            Canvas {
                x: -38; y: 8
                width: 42; height: 282
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.fillStyle = "#0b1c30";
                    ctx.strokeStyle = "#2a4a6a";
                    ctx.lineWidth = 2;
                    ctx.beginPath();
                    ctx.moveTo(38, 6);    // top-right (at front edge)
                    ctx.lineTo(4, 18);    // top-left (receded)
                    ctx.lineTo(4, 264);   // bottom-left (receded)
                    ctx.lineTo(38, 276);  // bottom-right (at front edge)
                    ctx.closePath();
                    ctx.fill();
                    ctx.stroke();
                }
            }
            // spine title text, vertical
            Text {
                x: -30; y: 60
                width: 24; height: 180
                rotation: -90
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: root.fontFamily
                font.pixelSize: 16
                font.letterSpacing: 4
                color: T.cream
                text: root.spineLabel
            }
            // top face: 2D parallelogram above the front, receding back.
            Canvas {
                x: 2; y: -30
                width: 262; height: 44
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.fillStyle = "#1d3a5c";
                    ctx.strokeStyle = "#2a4a6a";
                    ctx.lineWidth = 2;
                    ctx.beginPath();
                    ctx.moveTo(2, 38);     // front-left
                    ctx.lineTo(36, 6);     // back-left (receded)
                    ctx.lineTo(228, 6);    // back-right (receded)
                    ctx.lineTo(260, 38);   // front-right
                    ctx.closePath();
                    ctx.fill();
                    ctx.stroke();
                }
            }
        }  // box3d

        // cartridge in front, leaning against the box's lower right —
        // larger and more present for the hero's physical-media feel
        Item {
            x: 275; y: 155
            width: 220; height: 230
            rotation: -6
            GbaCartridge {
                scale: 0.44
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
        }  // gbaTilt (3D rotation)

        // Glossy-floor reflection: live mirror of the tilted composition,
        // faded into the floor.
        Item {
            x: 0; y: 292
            width: 640; height: 58
            clip: true
            ShaderEffectSource {
                width: 640; height: 350
                y: -350
                sourceItem: gbaTilt
                live: true
                hideSource: false
                transform: Scale { yScale: -1; origin.y: 350 }
                opacity: 0.22
            }
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#00000000" }
                    GradientStop { position: 1.0; color: "#0a141f" }
                }
            }
        }
    }

    // ================= PS2: case + disc =================
    Item {
        anchors.fill: parent
        visible: root.family === "ps2"

        // Warm glow; the scenic backdrop is provided by LibraryHero behind
        // the whole composition.
        Image {
            x: 20; y: 10
            width: 480; height: 340
            source: "../assets/hero/warm-glow.svg"
            smooth: true
            asynchronous: true
            opacity: 0.85
        }

        Item {
            id: ps2Tilt
            anchors.fill: parent
            transform: Rotation {
                origin.x: 200; origin.y: 150
                axis { x: 0; y: 1; z: 0 }
                angle: -16
            }

        Item {
            x: 40; y: -6
            scale: 0.85
            transformOrigin: Item.TopLeft

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
        }  // ps2 scale wrapper
        }  // ps2Tilt (3D rotation)

        // Glossy-floor reflection: live mirror of the tilted composition.
        Item {
            x: 0; y: 292
            width: 640; height: 58
            clip: true
            ShaderEffectSource {
                width: 640; height: 350
                y: -350
                sourceItem: ps2Tilt
                live: true
                hideSource: false
                transform: Scale { yScale: -1; origin.y: 350 }
                opacity: 0.22
            }
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#00000000" }
                    GradientStop { position: 1.0; color: "#0a141f" }
                }
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
