import QtQuick 2.12
import "CrystalTheme.js" as T

// Footer keycap: light pill with stepped pixel corners, dark navy glyphs.
// Measured from the hero: 82x41, "L1" / "R1" centered, subtle darker rim.
// Face buttons (A/B/Y) are circles, like a real gamepad.
Item {
    id: root
    width: root.circle ? root.diameter : T.keycapW
    height: root.circle ? root.diameter : T.keycapH

    property string text: ""
    property string fontFamily: "monospace"
    property bool circle: false
    property int diameter: 52

    Canvas {
        id: cap
        anchors.fill: parent
        // The user palette arrives asynchronously after first paint;
        // repaint so the keycap tracks it like every binding does.
        Connections {
            target: CrystalColors
            onCreamChanged: cap.requestPaint()
            onKeycapStrokeChanged: cap.requestPaint()
        }
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var w = width, h = height;
            if (root.circle) {
                ctx.beginPath();
                ctx.arc(w / 2, h / 2, w / 2 - 1, 0, Math.PI * 2);
                ctx.fillStyle = CrystalColors.cream;
                ctx.fill();
                ctx.lineWidth = 2;
                ctx.strokeStyle = CrystalColors.keycapStroke;
                ctx.stroke();
                return;
            }
            // stepped pixel corners: two 4px steps
            var s = 4;
            ctx.beginPath();
            ctx.moveTo(s * 2, 0);
            ctx.lineTo(w - s * 2, 0);  ctx.lineTo(w - s, s);
            ctx.lineTo(w - s, s * 2);   ctx.lineTo(w, s * 2);
            ctx.lineTo(w, h - s * 2);   ctx.lineTo(w - s, h - s * 2);
            ctx.lineTo(w - s, h - s);   ctx.lineTo(w - s * 2, h);
            ctx.lineTo(s * 2, h);      ctx.lineTo(s, h - s);
            ctx.lineTo(s, h - s * 2);   ctx.lineTo(0, h - s * 2);
            ctx.lineTo(0, s * 2);       ctx.lineTo(s, s * 2);
            ctx.lineTo(s, s);           ctx.closePath();
            ctx.fillStyle = CrystalColors.cream;
            ctx.fill();
            ctx.lineWidth = 2;
            ctx.strokeStyle = CrystalColors.keycapStroke;
            ctx.stroke();
        }
        Component.onCompleted: requestPaint()
    }

    Text {
        anchors.centerIn: parent
        font.family: root.fontFamily
        font.pixelSize: T.fontFooterPx
        font.letterSpacing: 1
        color: CrystalColors.creamInk
        text: root.text
    }
}
