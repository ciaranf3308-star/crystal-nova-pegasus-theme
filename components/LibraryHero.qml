import QtQuick 2.12
import QtGraphicalEffects 1.12
import "CrystalTheme.js" as T
import "CrystalAssets.js" as CrystalAssets
import "SystemMeta.js" as SystemMeta

// Left panel of the library hero: system kickers over an ambient art
// backdrop, the large physical-media composition, then the selected-game
// block (title / meta / description / screenshots).
Item {
    id: root

    property var collection: null
    property var game: null
    property string shortName: ""
    property string fontFamily: "monospace"
    // Crystal index epoch (art) + manifest epoch (editorial meta).
    property int artEpoch: 0
    property int metaEpoch: 0

    property var sysMeta: SystemMeta.metaFor(root.shortName)
    property string sysTitle: {
        var n = "";
        try { n = root.collection ? (root.collection.name || "") : ""; } catch (e) {}
        if (n === "") n = root.shortName;
        return n.toUpperCase();
    }
    property int gameCount: {
        try {
            if (root.collection && root.collection.games) return root.collection.games.count || 0
        } catch (e) {}
        return 0;
    }
    property string subLine: {
        var parts = [root.gameCount + " GAMES"];
        try {
            if (root.sysMeta.maker !== "") parts.push(root.sysMeta.maker);
            if (root.sysMeta.year !== "") parts.push(root.sysMeta.year);
        } catch (e) {}
        return parts.join("  |  ");
    }
    // Editorial metadata for the selected game ({} while loading/absent).
    property var gameMeta: {
        root.metaEpoch;
        try { return CrystalAssets.gameMeta(root.game, root.shortName); }
        catch (e) { return {}; }
    }
    property string metaLine: {
        var parts = [];
        try {
            if (root.gameMeta.genre) parts.push(String(root.gameMeta.genre).toUpperCase());
            if (root.gameMeta.players) parts.push(String(root.gameMeta.players));
            if (root.gameMeta.year) parts.push(String(root.gameMeta.year));
        } catch (e) {}
        return parts.join("  |  ");
    }
    property string gameTitle: {
        var t = "";
        try { t = root.game ? (root.game.title || "") : ""; } catch (e) {}
        return t === "" ? "UNTITLED" : t.toUpperCase();
    }
    property string description: {
        try { return root.gameMeta.description ? String(root.gameMeta.description) : ""; }
        catch (e) { return ""; }
    }
    property var stripArts: {
        root.artEpoch;
        var arts = [];
        try {
            var s = CrystalAssets.screenshot(root.game, root.shortName);
            if (s !== "") arts.push(s);
            var b = CrystalAssets.back(root.game, root.shortName);
            if (b !== "" && arts.length < 3) arts.push(b);
            var m = CrystalAssets.media(root.game, root.shortName);
            if (m !== "" && arts.length < 3) arts.push(m);
        } catch (e) {}
        return arts;
    }
    property string ambientArt: {
        root.artEpoch;
        try { return CrystalAssets.tileFront(root.game, root.shortName); }
        catch (e) { return ""; }
    }

    // ---- (dynamic per-game atmosphere is below; this old quiet
    // backdrop is removed to avoid double-layering) ----

    // ---- dynamic per-game atmosphere: selected game's art ----
    // Each game gets its own environmental feel (user: "same on all
    // games" was wrong). The art is shown full-bleed and dissolved into
    // an abstract color wash: heavy blur removes recognizability (no
    // giant faces), a strong top-down dark grade carries readability,
    // and a warm golden-hour tint keeps the premium feel. On device,
    // FastBlur provides the dissolve; the dark overlays are tuned to
    // carry the design even where blur is unavailable.
    Item {
        x: 0; y: 92
        width: 1280; height: 628
        visible: root.ambientArt !== ""

        Image {
            id: atmoSource
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: true
            cache: true
            source: root.ambientArt
            // hidden: the FastBlur below renders the blurred copy; this
            // keeps the source from double-painting on real hardware.
            // (The desktop preview shim leaves FastBlur transparent, so
            // nothing shows there — the dark grade below still applies.)
            visible: false
            // zoom slightly so blur edges never show the frame
            scale: 1.08
        }
        // Dissolves the art into an environmental wash on real hardware.
        FastBlur {
            anchors.fill: parent
            source: atmoSource
            radius: 96
            opacity: 0.55
        }
        // cinematic dark grade: deep at top (header legibility) and
        // bottom (selected-game legibility), breathing in the middle
        // where the physical media sits
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: CrystalColors.alpha(CrystalColors.heroDeep, 0xe6/255) }
                GradientStop { position: 0.28; color: CrystalColors.alpha(CrystalColors.gradientDark, 0xa6/255) }
                GradientStop { position: 0.52; color: CrystalColors.alpha(CrystalColors.gradientDark, 0x66/255) }
                GradientStop { position: 0.74; color: CrystalColors.alpha(CrystalColors.gradientDark, 0x8c/255) }
                GradientStop { position: 1.0; color: CrystalColors.alpha(CrystalColors.heroDeep, 0xe6/255) }
            }
        }
        // side vignette: keeps the frame edges moody like the reference
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: CrystalColors.alpha(CrystalColors.heroDeep, 0x80/255) }
                GradientStop { position: 0.18; color: CrystalColors.alpha(CrystalColors.heroDeep, 0) }
                GradientStop { position: 0.82; color: CrystalColors.alpha(CrystalColors.heroDeep, 0) }
                GradientStop { position: 1.0; color: CrystalColors.alpha(CrystalColors.heroDeep, 0x80/255) }
            }
        }
        // warm golden-hour grade
        Rectangle {
            anchors.fill: parent
            color: CrystalColors.amber
            opacity: 0.10
        }
    }
    // Fallback: system-specific gradient when no art is available
    Rectangle {
        x: 0; y: 92
        width: 1280; height: 628
        gradient: Gradient {
            GradientStop { position: 0.0; color: CrystalColors.heroGrad0 }
            GradientStop { position: 0.5; color: CrystalColors.heroShade }
            GradientStop { position: 1.0; color: CrystalColors.heroDeep }
        }
        visible: root.ambientArt === ""
    }

    // Scrim behind the system title for readability over the bright
    // backdrop. Declared BEFORE the text so it paints behind, not over.
    Rectangle {
        x: 0; y: T.heroTopY - 10
        width: 740; height: 150
        gradient: Gradient {
            GradientStop { position: 0.0; color: CrystalColors.heroDeep; }
            GradientStop { position: 0.6; color: CrystalColors.alpha(CrystalColors.heroDeep, 0xcc/255); }
            GradientStop { position: 1.0; color: "transparent"; }
        }
        visible: root.shortName === "gba" || root.shortName === "ps2"
    }

    // ---- system kickers ----
    Item {
        x: T.heroLeftX + 32; y: T.heroKickerY
        width: 600; height: 30
        Rectangle { width: 4; height: 22; y: 2; color: CrystalColors.frame }
        Text {
            x: 14; y: 0
            font.family: root.fontFamily
            font.pixelSize: T.heroKickerPx
            font.letterSpacing: 4
            color: CrystalColors.frame
            text: "LIBRARY"
        }
    }
    Text {
        x: T.heroLeftX + 32; y: T.sysTitleY
        width: 640
        elide: Text.ElideRight
        font.family: root.fontFamily
        font.pixelSize: T.sysTitlePx
        font.letterSpacing: 2
        color: CrystalColors.white
        style: Text.Outline
        styleColor: CrystalColors.tileDeep
        text: root.sysTitle
    }
    Text {
        x: T.heroLeftX + 34; y: T.sysSubY
        font.family: root.fontFamily
        font.pixelSize: T.sysSubPx
        font.letterSpacing: 3
        color: CrystalColors.labelHi
        style: Text.Outline
        styleColor: CrystalColors.tileDeep
        text: root.subLine
    }

    // script tagline (italic mono — no script face is bundled).
    // Sits just right of the box, left of the grid panel, like the
    // reference hero. Text outline carries readability (no boxy scrim).
    Text {
        x: 495; y: 265
        width: 210
        horizontalAlignment: Text.AlignRight
        font.family: root.fontFamily
        font.pixelSize: T.taglinePx
        font.italic: true
        color: CrystalColors.white
        opacity: 0.95
        style: Text.Outline
        styleColor: CrystalColors.tileDeep
        lineHeight: 1.3
        wrapMode: Text.WordWrap
        text: {
            try { return root.sysMeta.tagline || ""; } catch (e) { return ""; }
        }
    }

    // ---- physical composition ----
    GameBox3D {
        x: T.heroLeftX + 10; y: T.compY + 20
        width: 640; height: T.compH
        game: root.game
        shortName: root.shortName
        fontFamily: root.fontFamily
        artEpoch: root.artEpoch
    }

    // ---- selected game block ----
    Item {
        x: T.heroLeftX + 32; y: T.selKickerY
        width: 600; height: 24
        Rectangle { width: 4; height: 20; y: 1; color: CrystalColors.frame }
        Text {
            x: 14; y: 0
            font.family: root.fontFamily
            font.pixelSize: T.heroKickerPx
            font.letterSpacing: 4
            color: CrystalColors.frame
            text: "SELECTED GAME"
        }
    }
    Text {
        objectName: "libraryGameTitle"
        x: T.heroLeftX + 32; y: T.selTitleY
        width: 680
        elide: Text.ElideRight
        font.family: root.fontFamily
        font.pixelSize: T.selTitlePx
        font.letterSpacing: 1
        color: CrystalColors.ink
        text: root.gameTitle
    }
    Text {
        x: T.heroLeftX + 34; y: T.metaY
        width: T.metaW
        elide: Text.ElideRight
        font.family: root.fontFamily
        font.pixelSize: T.metaPx
        font.letterSpacing: 2
        color: CrystalColors.mutedBlue
        text: root.metaLine
        visible: root.metaLine !== ""
    }
    Text {
        x: T.heroLeftX + 34; y: T.descY
        width: T.descW
        font.family: root.fontFamily
        font.pixelSize: T.descPx
        color: CrystalColors.heroInk
        lineHeight: 1.28
        wrapMode: Text.WordWrap
        maximumLineCount: 4
        elide: Text.ElideRight
        text: root.description
        visible: root.description !== ""
    }

    // artwork strip: scraped screenshot first, then back / media art —
    // all real game imagery, hidden when the game has none scraped.
    Row {
        x: T.shotsX; y: T.shotsY
        spacing: 12
        visible: root.stripArts.length > 0
        Repeater {
            model: root.stripArts
            Rectangle {
                width: T.shotSize; height: T.shotSize
                color: CrystalColors.tile
                border.width: 2
                border.color: CrystalColors.borderDeep
                Image {
                    anchors.fill: parent
                    anchors.margins: 3
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true
                    source: modelData
                    visible: source !== "" && status === Image.Ready
                }
            }
        }
    }
}
