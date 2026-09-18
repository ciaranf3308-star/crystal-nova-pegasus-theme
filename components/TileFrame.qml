import QtQuick 2.12
import "CrystalTheme.js" as T

// Unselected tile frame, measured from the hero: 3px muted steel-blue
// border segments that stop 8px short of every corner, with a 5x5
// registration dot sitting in each corner gap. Deliberately firmware-crisp:
// plain rectangles, no rounding, no glow.
Item {
    id: root
    anchors.fill: parent

    property color frameColor: CrystalColors.frame

    // border segments (inset from corners by frameCornerCut)
    Rectangle { x: T.frameCornerCut; y: 0
                width: parent.width - 2 * T.frameCornerCut; height: T.frameBorderW
                color: root.frameColor }
    Rectangle { x: T.frameCornerCut; y: parent.height - T.frameBorderW
                width: parent.width - 2 * T.frameCornerCut; height: T.frameBorderW
                color: root.frameColor }
    Rectangle { x: 0; y: T.frameCornerCut
                width: T.frameBorderW; height: parent.height - 2 * T.frameCornerCut
                color: root.frameColor }
    Rectangle { x: parent.width - T.frameBorderW; y: T.frameCornerCut
                width: T.frameBorderW; height: parent.height - 2 * T.frameCornerCut
                color: root.frameColor }

    // corner registration dots, centred in the gaps
    Repeater {
        model: [ [0, 0],
                 [1, 0],
                 [0, 1],
                 [1, 1] ]
        Rectangle {
            property int cx: modelData[0]
            property int cy: modelData[1]
            x: cx === 0 ? (T.frameCornerCut - T.frameDotSize) / 2
                        : parent.width - T.frameCornerCut - (T.frameCornerCut - T.frameDotSize) / 2 - T.frameDotSize
            y: cy === 0 ? (T.frameCornerCut - T.frameDotSize) / 2
                        : parent.height - T.frameCornerCut - (T.frameCornerCut - T.frameDotSize) / 2 - T.frameDotSize
            width: T.frameDotSize
            height: T.frameDotSize
            color: root.frameColor
        }
    }
}
