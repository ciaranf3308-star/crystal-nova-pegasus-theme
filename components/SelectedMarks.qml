import QtQuick 2.12
import "CrystalTheme.js" as T

// Selected-tile corner marks, measured from the hero: four dark navy
// "viewfinder" brackets, 8px-thick arms 32px long, inset 7px from the
// tile edges. Same registration-mark language as the unselected frame's
// corner dots. Static rectangles — no animation.
Item {
    id: root
    anchors.fill: parent

    property color markColor: T.creamInk

    // top-left
    Rectangle { x: T.markInset; y: T.markInset
                width: T.markLen; height: T.markThick; color: root.markColor }
    Rectangle { x: T.markInset; y: T.markInset
                width: T.markThick; height: T.markLen; color: root.markColor }
    // top-right
    Rectangle { x: parent.width - T.markInset - T.markLen; y: T.markInset
                width: T.markLen; height: T.markThick; color: root.markColor }
    Rectangle { x: parent.width - T.markInset - T.markThick; y: T.markInset
                width: T.markThick; height: T.markLen; color: root.markColor }
    // bottom-left
    Rectangle { x: T.markInset; y: parent.height - T.markInset - T.markThick
                width: T.markLen; height: T.markThick; color: root.markColor }
    Rectangle { x: T.markInset; y: parent.height - T.markInset - T.markLen
                width: T.markThick; height: T.markLen; color: root.markColor }
    // bottom-right
    Rectangle { x: parent.width - T.markInset - T.markLen; y: parent.height - T.markInset - T.markThick
                width: T.markLen; height: T.markThick; color: root.markColor }
    Rectangle { x: parent.width - T.markInset - T.markThick; y: parent.height - T.markInset - T.markLen
                width: T.markThick; height: T.markLen; color: root.markColor }
}
