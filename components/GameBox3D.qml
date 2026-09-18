import QtQuick 2.12
import "CrystalTheme.js" as T
import "CrystalAssets.js" as CrystalAssets
import "SystemMeta.js" as SystemMeta
import "PhysicalMedia"
import "PhysicalMedia/MediaTemplates.js" as MT

// Library hero physical composition: the selected game's physical media,
// rendered large. GBA: bespoke game box (branded spine + cover front)
// with a cartridge in front. PS2: bespoke DVD case with cover art and
// the disc leaning beside it. Cart/disc families: generic cartridge /
// disc compositions with the game's art. Every other system: large
// framed cover art — never a placeholder card.
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
        try {
            var dn = SystemMeta.metaFor(root.shortName).name;
            if (dn) return String(dn).toUpperCase();
        } catch (e) {}
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
        color: CrystalColors.black
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

        // Box: FLAT straight-on presentation matching the reference hero.
        // Wide black spine on the left with large vertical white text,
        // large square front with cover art. No top face, no angled
        // fake-3D — the reference is a clean front view.
        Item {
            id: gbaTilt
            anchors.fill: parent

        Item {
            id: box3d
            x: 10; y: 0
            // spine: flat wide black strip, left edge of the box
            Rectangle {
                id: gbaSpine
                x: 0; y: 0
                width: 110; height: 352
                color: CrystalColors.boxBlack
                border.width: 2
                border.color: CrystalColors.spineBorder
                // subtle vertical highlight on the spine's right edge
                Rectangle {
                    x: parent.width - 3; y: 0
                    width: 3; height: parent.height
                    color: CrystalColors.spineHi
                    opacity: 0.6
                }
                Text {
                    anchors.centerIn: parent
                    width: 340; height: 40
                    rotation: -90
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: root.fontFamily
                    font.pixelSize: 28
                    font.bold: true
                    font.letterSpacing: 6
                    color: CrystalColors.inkBright
                    text: root.spineLabel
                }
            }
            // front face: large square cover art, flush against the spine
            Rectangle {
                id: gbaBoxFront
                x: 110; y: 0
                width: 330; height: 352
                color: CrystalColors.tile
                border.width: 2
                border.color: CrystalColors.borderDeep
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
        }  // box3d

        // cartridge in front of the box's lower-right, like the reference —
        // small, subtle, overlapping the front. Bottom clears the kicker.
        Item {
            x: 285; y: 185
            width: 180; height: 190
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
                    GradientStop { position: 0.0; color: CrystalColors.clear }
                    GradientStop { position: 1.0; color: CrystalColors.gradientDark }
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
                color: CrystalColors.boxPanel
                border.width: 2
                border.color: CrystalColors.boxBorder
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
                    color: CrystalColors.background
                    border.width: 2
                    border.color: CrystalColors.boxBorder
                }
            }
            // disc sheen arc
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: 14
                border.color: CrystalColors.white
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
                    GradientStop { position: 0.0; color: CrystalColors.clear }
                    GradientStop { position: 1.0; color: CrystalColors.gradientDark }
                }
            }
        }
    }

    // ================= generic cartridge (cart family) =================
    // Cartridge-based systems (GB/GBC, NES/SNES, N64, Genesis, ...):
    // a clean cartridge silhouette with the game's art as the label.
    // Simple flat shapes only — no rotation, no clipping, no nesting.
    Item {
        anchors.fill: parent
        visible: root.family === "cart"
        // cartridge body
        Rectangle {
            x: 170; y: 40
            width: 240; height: 320
            radius: 16
            color: CrystalColors.panelDark
            border.width: 2
            border.color: CrystalColors.panelBorder
        }
        // label with game art
        Rectangle {
            x: 194; y: 120
            width: 192; height: 170
            radius: 8
            color: CrystalColors.tile
            border.width: 2
            border.color: CrystalColors.borderDeep
        }
        Image {
            x: 198; y: 124
            width: 184; height: 162
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: true
            source: root.frontArt
            visible: source !== "" && status === Image.Ready
        }
        Text {
            x: 194; y: 185
            width: 192
            horizontalAlignment: Text.AlignHCenter
            font.family: root.fontFamily
            font.pixelSize: 22
            font.letterSpacing: 3
            color: CrystalColors.frame
            text: root.spineLabel
            visible: root.frontArt === ""
        }
        // title under the label
        Text {
            x: 170; y: 300
            width: 240
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.family: root.fontFamily
            font.pixelSize: 18
            font.letterSpacing: 2
            color: CrystalColors.tileInk
            text: {
                var t = "";
                try { t = root.game ? (root.game.title || "") : ""; } catch (e) {}
                return t.toUpperCase();
            }
        }
    }

    // ================= generic disc (disc family) =================
    // Optical-media systems (PS1, Dreamcast, Saturn, ...): a disc with
    // the game's art leaning against a slim system spine.
    Item {
        anchors.fill: parent
        visible: root.family === "disc"
        // slim spine with system name
        Rectangle {
            x: 90; y: 50
            width: 60; height: 310
            color: CrystalColors.boxBlack
            border.width: 2
            border.color: CrystalColors.spineBorder
        }
        Text {
            x: 90; y: 195
            width: 60
            horizontalAlignment: Text.AlignHCenter
            font.family: root.fontFamily
            font.pixelSize: 16
            font.bold: true
            font.letterSpacing: 2
            color: CrystalColors.batteryFill
            text: root.spineLabel.substring(0, 4)
        }
        // disc
        Rectangle {
            x: 190; y: 60
            width: 280; height: 280
            radius: 140
            color: CrystalColors.boxPanel
            border.width: 3
            border.color: CrystalColors.panelBorder
            clip: true
            Image {
                anchors.fill: parent
                anchors.margins: 6
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                source: root.frontArt
                visible: source !== "" && status === Image.Ready
            }
        }
        Text {
            x: 190; y: 130
            width: 280
            horizontalAlignment: Text.AlignHCenter
            font.family: root.fontFamily
            font.pixelSize: 20
            font.letterSpacing: 3
            color: CrystalColors.frame
            text: root.spineLabel
            visible: root.frontArt === ""
        }
        // hub
        Rectangle {
            x: 308; y: 178
            width: 44; height: 44
            radius: 22
            color: CrystalColors.background
            border.width: 2
            border.color: CrystalColors.panelBorder
        }
    }

    // ================= other systems: framed cover =================
    Item {
        anchors.fill: parent
        visible: root.family !== "gba" && root.family !== "ps2" &&
                 root.family !== "cart" && root.family !== "disc"
        Rectangle {
            anchors.centerIn: parent
            width: 300; height: 336
            color: CrystalColors.tile
            border.width: 2
            border.color: CrystalColors.borderDeep
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
