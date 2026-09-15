import QtQuick 2.12

// Battery level indicator driven by the real Pegasus device API:
//   api.device.batteryPercent  (float, 0..1)
//   api.device.batteryCharging (bool)
//   api.device.batteryStatus   (enum: Unknown/NoBattery/Discharging/Charging/Charged)
// Unknown / no-battery devices render an empty outline; nothing is faked.
Item {
    id: root
    width: 58
    height: 32

    property real level: {
        var p = api.device.batteryPercent
        return (p === undefined || isNaN(p) || p < 0) ? -1 : Math.min(1, p)
    }
    property bool charging: !!api.device.batteryCharging

    property color frame: "#8ba3b5"
    property color fill: root.charging ? "#e8f2f8"
                     : root.level < 0 ? "transparent"
                     : root.level < 0.2 ? "#c46a5a"
                     : "#9fc4d8"

    Rectangle { // outer shell
        width: 48
        height: 22
        anchors.verticalCenter: parent.verticalCenter
        color: "transparent"
        border.color: root.frame
        border.width: 2
        radius: 3
    }
    Rectangle { // terminal nub
        x: 48
        width: 5
        height: 10
        anchors.verticalCenter: parent.verticalCenter
        color: root.frame
        radius: 1
    }
    Rectangle { // charge fill
        x: 5
        width: Math.max(0, 38 * root.level)
        height: 12
        anchors.verticalCenter: parent.verticalCenter
        color: root.fill
        radius: 1
        visible: root.level >= 0
    }
}
