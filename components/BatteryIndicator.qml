import QtQuick 2.12
import "CrystalTheme.js" as T

// Battery level indicator, measured from the hero: 70x32 shell with a
// terminal nub and segmented charge fill. Driven by the real Pegasus
// device API; unknown / no-battery devices render an empty outline.
Item {
    id: root

    property real level: {
        var p = api.device.batteryPercent
        return (p === undefined || isNaN(p) || p < 0) ? -1 : Math.min(1, p)
    }
    property bool charging: !!api.device.batteryCharging

    property int segments: 4
    property int filledSegments: root.level < 0 ? 0
                                 : Math.round(root.level * root.segments)

    Rectangle { // outer shell
        x: 0; y: 2
        width: 62; height: 28
        color: "transparent"
        border.color: T.batteryFrame
        border.width: 2
    }
    Rectangle { // terminal nub
        x: 62; y: 10
        width: 6; height: 12
        color: T.batteryFrame
    }
    Row { // segmented charge fill
        x: 6; y: 7
        spacing: 3
        Repeater {
            model: root.segments
            Rectangle {
                width: 11; height: 18
                color: index < root.filledSegments
                       ? (root.charging ? T.primaryInk
                          : root.level < 0.2 ? T.batteryLow : T.batteryFill)
                       : "transparent"
            }
        }
    }
}
