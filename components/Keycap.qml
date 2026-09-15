import QtQuick 2.12
import "CrystalTheme.js" as T

// Footer keycap: light pill with stepped pixel corners, dark navy glyphs.
// Measured from the hero: 82x41, "L1" / "R1" centered, subtle darker rim.
Item {
    id: root
    width: T.keycapW
    height: T.keycapH

    property string text: ""
    property string fontFamily: "monospace"

    Canvas {
        id: cap
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var w = width, h = height;
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
            ctx.fillStyle = T.keycapFill;
            ctx.fill();
            ctx.lineWidth = 2;
            ctx.strokeStyle = "#a9bccd";
            ctx.stroke();
        }
        Component.onCompleted: requestPaint()
    }

    Text {
        anchors.centerIn: parent
        font.family: root.fontFamily
        font.pixelSize: T.fontFooterPx
        font.letterSpacing: 1
        color: T.keycapInk
        text: root.text
    }
}
