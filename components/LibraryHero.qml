import QtQuick 2.12
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

    // ---- ambient backdrop: selected game's cover, dark and quiet ----
    // Sits below the header (y 100+) so it never dims the status bar.
    Image {
        id: ambientBg
        x: T.heroLeftX; y: T.heroTopY
        width: T.heroLeftW; height: 700
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        source: root.ambientArt
        opacity: 0.18
        visible: source !== "" && status === Image.Ready
    }
    Rectangle {
        x: T.heroLeftX; y: T.heroTopY
        width: T.heroLeftW; height: 700
        visible: ambientBg.visible
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0a1929"; }
            GradientStop { position: 0.18; color: "#0a192900"; }
            GradientStop { position: 0.82; color: "#0a192900"; }
            GradientStop { position: 1.0; color: "#0a1929"; }
        }
        opacity: 0.6
    }

    // ---- scenic environment: per-game atmosphere ----
    // The selected game's art, heavily blurred and darkened, fills the
    // hero as a full-bleed backdrop. This gives every game its own
    // atmosphere instead of one static image for all.
    Image {
        x: 0; y: 0
        width: 1280; height: 720
        source: {
            try {
                var a = CrystalAssets.front(root.game, root.shortName);
                return a !== "" ? a : "../assets/hero/gba-backdrop.png";
            } catch (e) { return "../assets/hero/gba-backdrop.png"; }
        }
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        opacity: 0.55
        visible: root.shortName === "gba" || root.shortName === "ps2"
    }
    // Darken the blurred art so text stays readable
    Rectangle {
        x: 0; y: 0
        width: 1280; height: 720
        color: "#060d18"
        opacity: 0.35
        visible: root.shortName === "gba" || root.shortName === "ps2"
    }

    // ---- system kickers ----
    Item {
        x: T.heroLeftX + 32; y: T.heroKickerY
        width: 600; height: 30
        Rectangle { width: 4; height: 22; y: 2; color: "#7ba7d9" }
        Text {
            x: 14; y: 0
            font.family: root.fontFamily
            font.pixelSize: T.heroKickerPx
            font.letterSpacing: 4
            color: "#7ba7d9"
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
        color: T.primaryInk
        text: root.sysTitle
    }
    Text {
        x: T.heroLeftX + 34; y: T.sysSubY
        font.family: root.fontFamily
        font.pixelSize: T.sysSubPx
        font.letterSpacing: 3
        color: "#e8f1f8"
        style: Text.Outline
        styleColor: "#0a1626"
        text: root.subLine
    }

    // (tagline removed 2026-09-18: caused text overlap/clipping with
    // the subline and the 3D box; the subline carries the system info)

    // Scrim behind the system title for readability over the bright backdrop.
    Rectangle {
        x: 0; y: T.heroTopY - 10
        width: 740; height: 150
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#060d18"; }
            GradientStop { position: 0.6; color: "#060d18cc"; }
            GradientStop { position: 1.0; color: "transparent"; }
        }
        visible: root.shortName === "gba" || root.shortName === "ps2"
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
        Rectangle { width: 4; height: 20; y: 1; color: "#7ba7d9" }
        Text {
            x: 14; y: 0
            font.family: root.fontFamily
            font.pixelSize: T.heroKickerPx
            font.letterSpacing: 4
            color: "#7ba7d9"
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
        color: T.primaryInk
        text: root.gameTitle
    }
    Text {
        x: T.heroLeftX + 34; y: T.metaY
        font.family: root.fontFamily
        font.pixelSize: T.metaPx
        font.letterSpacing: 2
        color: "#9fb2c2"
        text: root.metaLine
        visible: root.metaLine !== ""
    }
    Text {
        x: T.heroLeftX + 34; y: T.descY
        width: T.descW
        font.family: root.fontFamily
        font.pixelSize: T.descPx
        color: "#a9c0d4"
        lineHeight: 1.35
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
                color: "#0e2236"
                border.width: 2
                border.color: "#2a4a6a"
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
