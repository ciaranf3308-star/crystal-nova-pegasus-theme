pragma Singleton
import QtQuick 2.12

// CrystalColors — user-overridable theme palette.
//
// The four BASE colors (background, accent, cream, joystick) are the
// user-facing identity. The Manager app writes them to
// <themes-root>/crystal-user-colors.json:
//
//   {"version":1,"background":"#0a1929","accent":"#7ba7d9",
//    "cream":"#f0ebdc","joystick":"#ffc93c","updated":<epochSeconds>}
//
// All four keys are optional; theme.qml loads the file once at theme
// startup and assigns only present + valid (^#[0-9a-fA-F]{6}$) keys,
// flipping the matching *Custom flag. Every other color below is
// DERIVED from its base, so overriding one base recolors the whole
// ramp coherently. NOTE: a cold Pegasus restart picks up color changes.
//
// Pixel-identity guarantee: with no user file present, every property
// evaluates to the EXACT hex literal it replaced in the theme (values
// measured from the approved hero / CrystalTheme.js). Derived
// properties use the form
//     baseCustom ? Qt.lighter(base, F) : "#rrggbb"
// so defaults are literals, never computed approximations. A missing,
// malformed, or invalid colors file leaves every default in place —
// a colors problem can never break rendering.
QtObject {
    // ------------------------------------------------------------------
    // Base colors — the only properties the user file may override.
    // ------------------------------------------------------------------
    property color background: "#0a1929" // very dark navy screen
    property color accent:     "#7ba7d9" // muted steel-blue frame
    property color cream:      "#f0ebdc" // warm ivory selection
    property color joystick:   "#ffd23f" // Nova yellow sticks

    // Flipped alongside the matching base when a user color is applied.
    // Only theme.qml's startup loader writes these.
    property bool backgroundCustom: false
    property bool accentCustom:     false
    property bool creamCustom:      false
    property bool joystickCustom:    false

    // Alpha-composited variant of a color (a in 0..1). Used for
    // gradient veil stops so they track their base when customized.
    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }

    // ------------------------------------------------------------------
    // Background family — deep navy surfaces.
    // ------------------------------------------------------------------
    property color tile:            backgroundCustom ? Qt.lighter(background, 1.32) : "#0e2236"
    property color tileDeep:        backgroundCustom ? Qt.darker(background, 1.08)  : "#0a1626"
    property color selectedOutline: backgroundCustom ? Qt.darker(background, 1.30)  : "#081425"
    property color gradientDark:    backgroundCustom ? Qt.darker(background, 1.22)  : "#0a141f"
    property color boxBlack:        backgroundCustom ? Qt.darker(background, 1.40)  : "#0b0e14"
    property color heroShade:       backgroundCustom ? Qt.darker(background, 1.12)  : "#0c1626"
    property color heroDeep:        backgroundCustom ? Qt.darker(background, 1.55)  : "#060d18"
    property color headerShade:     backgroundCustom ? Qt.darker(background, 1.45)  : "#081120"
    property color inspectShade:    backgroundCustom ? Qt.darker(background, 1.70)  : "#050c14"
    property color cartWell:        backgroundCustom ? Qt.lighter(background, 1.18) : "#0c1c30"
    property color gridTile:        backgroundCustom ? Qt.lighter(background, 1.28) : "#0c2036"
    property color boxPanel:        backgroundCustom ? Qt.lighter(background, 1.50) : "#101c2c"
    property color caseShade:       backgroundCustom ? Qt.lighter(background, 1.45) : "#101a2a"
    property color windowBacking:   backgroundCustom ? Qt.lighter(background, 1.42) : "#101722"
    property color heroGrad0:       backgroundCustom ? Qt.lighter(background, 1.32) : "#0e1a2a"
    property color wellBacking:     backgroundCustom ? Qt.lighter(background, 2.00) : "#16304a"
    property color spineBorder:     backgroundCustom ? Qt.lighter(background, 1.90) : "#1a2230"
    property color caseGrad0:       backgroundCustom ? Qt.lighter(background, 2.10) : "#1b2a40"
    property color panelDark:       backgroundCustom ? Qt.lighter(background, 2.60) : "#232b36"
    property color spineHi:         backgroundCustom ? Qt.lighter(background, 2.70) : "#232f45"
    property color discHub:         backgroundCustom ? Qt.lighter(background, 2.80) : "#24344a"

    // ------------------------------------------------------------------
    // Accent family — steel-blue frames, inks, hairlines.
    // ------------------------------------------------------------------
    property color frame:        accentCustom ? accent : "#7ba7d9"
    property color frameDim:     accentCustom ? Qt.darker(accent, 1.85)  : "#3a5a7a"
    property color borderDeep:   accentCustom ? Qt.darker(accent, 2.20)  : "#2a4a6a"
    property color gridBorder:   accentCustom ? Qt.darker(accent, 2.30)  : "#26456a"
    property color boxBorder:    accentCustom ? Qt.darker(accent, 1.75)  : "#3a5f8a"
    property color panelBorder:  accentCustom ? Qt.darker(accent, 1.70)  : "#3d4a5e"
    property color cartHi:       accentCustom ? Qt.darker(accent, 1.04)  : "#7ba3cc"
    property color cartGradHi:   accentCustom ? Qt.lighter(accent, 1.35) : "#b9d4ea"
    property color probeLink:    accentCustom ? Qt.lighter(accent, 1.20) : "#7fd4ff"
    property color dimText:       accentCustom ? Qt.lighter(accent, 1.12) : "#8ba3b5"
    property color tileInk:      accentCustom ? Qt.lighter(accent, 1.15) : "#d7e3ec"
    property color ink:          accentCustom ? Qt.lighter(accent, 1.30) : "#e9f1f6"
    property color inkBright:    accentCustom ? Qt.lighter(accent, 1.38) : "#f2f6fa"
    property color labelHi:      accentCustom ? Qt.lighter(accent, 1.32) : "#e8f1f8"
    property color batteryFill:  accentCustom ? Qt.lighter(accent, 1.28) : "#dfe9f1"
    property color discHi:       accentCustom ? Qt.lighter(accent, 1.34) : "#e6eef6"
    property color discLo:       accentCustom ? Qt.lighter(accent, 1.22) : "#a9bfd4"
    property color discBacking:  accentCustom ? Qt.lighter(accent, 1.18) : "#9fb4c9"
    property color mutedBlue:    accentCustom ? Qt.darker(accent, 1.12)  : "#9fb2c2"
    property color keycapStroke: accentCustom ? Qt.darker(accent, 1.08)  : "#a9bccd"
    property color heroInk:      accentCustom ? Qt.lighter(accent, 1.20) : "#a9c0d4"
    property color dimInk:       accentCustom ? Qt.darker(accent, 1.50)  : "#6a8499"
    property color probeDim:      accentCustom ? Qt.darker(accent, 1.45)  : "#8a93a6"
    property color divider:       accentCustom ? Qt.darker(accent, 1.30)  : "#8fa5b8"

    // ------------------------------------------------------------------
    // Cream family — warm ivory selection treatment.
    // ------------------------------------------------------------------
    property color creamInk:  creamCustom ? Qt.darker(cream, 3.00) : "#1b2c4e"

    // ------------------------------------------------------------------
    // Joystick family — Nova yellow accents.
    // ------------------------------------------------------------------
    property color amber:      joystickCustom ? Qt.darker(joystick, 1.25) : "#ff9a3c"

    // ------------------------------------------------------------------
    // Constants — never derived. Pure neutrals stay neutral and
    // diagnostic reds stay red no matter the user palette.
    // ------------------------------------------------------------------
    property color white:      "#ffffff"
    property color black:      "#000000"
    property color clear:      "#00000000"
    property color bad:        "#ff6b6b"
    property color badDeep:    "#c46a5a"
    property color probePanel: "#3a0d0d"
}
