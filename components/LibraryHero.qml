import QtQuick 2.12
import QtGraphicalEffects 1.12
import "CrystalTheme.js" as T
import "CrystalAssets.js" as CrystalAssets
import "SystemMeta.js" as SystemMeta

// Left hero panel (rebuilt 2026-09-19): the emotional side of the library.
// System identity dominates the top; the selected game is the hero object
// in the middle; game details anchor the bottom. Generous space, no chrome.
Item {
    id: root

    property var collection: null
    property var game: null
    property string shortName: ""
    property string fontFamily: "monospace"
    property int artEpoch: 0
    property int metaEpoch: 0

    property var sysMeta: SystemMeta.metaFor(root.shortName)
    property string sysTitle: {
        var n = "";
        try { n = root.collection ? (root.collection.name || "") : ""; } catch (e) {}
        if (n === "") n = root.shortName;
        return n.toUpperCase();
    }
    // Responsive system title size: long names (e.g. NINTENDO GAME BOY
    // ADVANCE) shrink instead of truncating mid-word.
    property int sysTitlePx: {
        var len = root.sysTitle.length;
        if (len <= 12) return 64;
        if (len <= 18) return 54;
        if (len <= 24) return 44;
        return 36;
    }
    // Allow a controlled two-line treatment for very long names.
    property bool sysTitleTwoLine: root.sysTitle.length > 26
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
        return parts.join("   ·   ");
    }
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
        return parts.join("   ·   ");
    }
    property string gameTitle: {
        var t = "";
        try { t = root.game ? (root.game.title || "") : ""; } catch (e) {}
        return t === "" ? "UNTITLED" : t.toUpperCase();
    }
    // Responsive game title: shrink before resorting to ellipsis.
    property int gameTitlePx: {
        var len = root.gameTitle.length;
        if (len <= 20) return 34;
        if (len <= 30) return 28;
        return 24;
    }
    property string description: {
        try { return root.gameMeta.description ? String(root.gameMeta.description) : ""; }
        catch (e) { return ""; }
    }
    property string ambientArt: {
        root.artEpoch;
        try { return CrystalAssets.tileFront(root.game, root.shortName); }
        catch (e) { return ""; }
    }

    // ---- ambient backdrop: selected game's art as environmental wash ----
    // Heavy blur dissolves recognizability; dark grade carries readability.
    Item {
        x: 0; y: 92
        width: 768; height: 640
        visible: root.ambientArt !== ""
        clip: true

        Image {
            id: atmoSource
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: true
            cache: true
            source: root.ambientArt
            visible: false
            scale: 1.08
        }
        FastBlur {
            anchors.fill: parent
            source: atmoSource
            radius: 96
            opacity: 0.5
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: CrystalColors.alpha(CrystalColors.heroDeep, 0xe6/255) }
                GradientStop { position: 0.3; color: CrystalColors.alpha(CrystalColors.gradientDark, 0xa6/255) }
                GradientStop { position: 0.55; color: CrystalColors.alpha(CrystalColors.gradientDark, 0x66/255) }
                GradientStop { position: 0.78; color: CrystalColors.alpha(CrystalColors.gradientDark, 0x8c/255) }
                GradientStop { position: 1.0; color: CrystalColors.alpha(CrystalColors.heroDeep, 0xe6/255) }
            }
        }
        Rectangle {
            anchors.fill: parent
            color: CrystalColors.amber
            opacity: 0.08
        }
    }
    // Fallback gradient when no art is available.
    Rectangle {
        x: 0; y: 92
        width: 768; height: 640
        gradient: Gradient {
            GradientStop { position: 0.0; color: CrystalColors.heroGrad0 }
            GradientStop { position: 0.5; color: CrystalColors.heroShade }
            GradientStop { position: 1.0; color: CrystalColors.heroDeep }
        }
        visible: root.ambientArt === ""
    }

    // ---- system identity ----
    // LIBRARY eyebrow
    Text {
        x: T.heroLeftX; y: T.heroKickerY
        font.family: root.fontFamily
        font.pixelSize: T.heroKickerPx
        font.letterSpacing: 5
        color: CrystalColors.frame
        text: "LIBRARY"
    }
    // System name — dominates the screen. Responsive size, two-line
    // treatment for very long names. Never ugly mid-word truncation.
    Text {
        x: T.heroLeftX; y: T.sysTitleY
        width: T.heroLeftW
        font.family: root.fontFamily
        font.pixelSize: root.sysTitlePx
        font.letterSpacing: 2
        font.bold: true
        color: CrystalColors.white
        wrapMode: root.sysTitleTwoLine ? Text.WordWrap : Text.NoWrap
        maximumLineCount: root.sysTitleTwoLine ? 2 : 1
        elide: Text.ElideRight
        lineHeight: 1.05
        text: root.sysTitle
    }
    // System metadata
    Text {
        x: T.heroLeftX + 2; y: T.sysSubY
        font.family: root.fontFamily
        font.pixelSize: T.sysSubPx
        font.letterSpacing: 2
        color: CrystalColors.labelHi
        opacity: 0.85
        text: root.subLine
    }

    // Thin rule separating system identity from the hero object.
    Rectangle {
        x: T.heroLeftX; y: T.sysSubY + 32
        width: 64; height: 2
        color: CrystalColors.frame
        opacity: 0.5
    }

    // ---- selected-game hero object ----
    // Large physical media composition. The game is the hero, not a
    // scraper thumbnail.
    GameBox3D {
        x: T.heroLeftX - 8; y: T.compY
        width: T.heroLeftW + 16; height: T.compH
        game: root.game
        shortName: root.shortName
        fontFamily: root.fontFamily
        artEpoch: root.artEpoch
    }

    // ---- selected game details ----
    Text {
        x: T.heroLeftX; y: T.selKickerY
        font.family: root.fontFamily
        font.pixelSize: T.heroKickerPx
        font.letterSpacing: 5
        color: CrystalColors.frame
        text: "SELECTED GAME"
    }
    Text {
        objectName: "libraryGameTitle"
        x: T.heroLeftX; y: T.selTitleY
        width: T.heroLeftW
        font.family: root.fontFamily
        font.pixelSize: root.gameTitlePx
        font.letterSpacing: 1
        font.bold: true
        color: CrystalColors.ink
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
        lineHeight: 1.1
        text: root.gameTitle
    }
    Text {
        x: T.heroLeftX + 2; y: T.metaY
        width: T.metaW
        elide: Text.ElideRight
        font.family: root.fontFamily
        font.pixelSize: T.metaPx
        font.letterSpacing: 2
        color: CrystalColors.mutedBlue
        opacity: 0.85
        text: root.metaLine
        visible: root.metaLine !== ""
    }
    // Description: only if there is genuinely space (below the meta line,
    // above the footer). Kept short and quiet.
    Text {
        x: T.heroLeftX + 2; y: T.descY
        width: T.descW
        font.family: root.fontFamily
        font.pixelSize: T.descPx
        color: CrystalColors.heroInk
        opacity: 0.75
        lineHeight: 1.35
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
        text: root.description
        visible: root.description !== ""
    }
}
