import QtQuick 2.12
import QtGraphicalEffects 1.12
import "MediaTemplates.js" as MT

// Ps2Case — thin compositor over authored SVG templates.
//
// The keep case is NEVER drawn here: it comes from
// assets/physical/ps2/*.svg (original Crystal illustration). QML only
// layers game artwork into the template's transparent windows and adds
// small dynamic overlays (disc lift for launch, restrained view dip).
//
// FRONT / SPINE / BACK are views of the SAME object: one shared
// plastic language, one continuous cover-art set. OPEN is a
// deliberately composed spread (interior panel + hinge + tray + disc),
// not a rotated rectangle.
//
// view: "front" | "spine" | "back" | "open"
// discKind: "scan" (real disc art) | "art" (cover art under the disc
//   template) | "none" (designed fallback disc face)
Item {
    id: root
    implicitWidth: isOpen ? MT.PS2.openW
                          : (isSpine ? MT.PS2.spineW : MT.PS2.caseW)
    implicitHeight: isOpen ? MT.PS2.openH : MT.PS2.caseH

    property string view: "front"
    property string frontArt: ""
    property string spineArt: ""
    property string backArt: ""
    property string discArt: ""
    property string discKind: "none"
    property string titleText: ""
    property string fontFamily: "monospace"
    property bool lifting: false   // PS2 launch: disc lifts from the tray

    readonly property string assetBase: "../../assets/physical/ps2/"
    readonly property bool isOpen: root.view === "open"
    readonly property bool isSpine: root.view === "spine"
    // face texture for the current closed view. BACK shows real back
    // artwork only — never the front cover again; when backArt is
    // absent the renderer builds a deliberate Crystal back composition
    // (backComposed) instead of re-showing the front.
    readonly property string faceArt: root.view === "spine" ? root.spineArt
        : (root.view === "back" ? root.backArt : root.frontArt)
    readonly property bool backComposed: root.view === "back"
                                         && root.backArt === ""

    // restrained view-change settle: a 140ms dip, never a spin
    NumberAnimation {
        id: viewDip
        target: root; property: "opacity"
        from: 0.55; to: 1; duration: 140
    }
    onViewChanged: viewDip.restart()

    // ---- soft shadow (authored, under everything) ----
    Image {
        source: root.assetBase + "case-shadow.svg"
        width: root.isOpen ? 1500 : 820
        height: root.isOpen ? 300 : 164
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height - (root.isOpen ? 108 : 62)
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: true
    }

    // ---- CLOSED: front / spine / back ----
    Item {
        anchors.fill: parent
        visible: !root.isOpen

        // game artwork clipped to the template window (QML layering,
        // never an SVG mask)
        Rectangle {
            x: root.isSpine ? MT.PS2.spineArtX : MT.PS2.coverX
            y: root.isSpine ? MT.PS2.spineArtY : MT.PS2.coverY
            width: root.isSpine ? MT.PS2.spineArtW : MT.PS2.coverW
            height: root.isSpine ? MT.PS2.spineArtH : MT.PS2.coverH
            radius: 6
            clip: true
            color: "#101722"   // window backing: visible only if art fails

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                source: root.faceArt !== "" ? root.faceArt : ""
                visible: source !== "" && status === Image.Ready
            }

            // designed fallback cover (front only): a real composition
            // hierarchy from title + Crystal treatment, never a
            // placeholder card. (Back has its own composed fallback
            // below; the front cover is never re-shown as the back.)
            Item {
                anchors.fill: parent
                visible: !root.isSpine && root.view !== "back"
                         && root.faceArt === ""
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#16304a" }
                        GradientStop { position: 1.0; color: "#0a1626" }
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 40
                    color: "transparent"
                    border.width: 2
                    border.color: "#7ba7d9"
                    opacity: 0.45
                }
                Text {
                    anchors.centerIn: parent
                    width: parent.width - 120
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    maximumLineCount: 4
                    font.family: root.fontFamily
                    font.pixelSize: 46
                    font.letterSpacing: 6
                    lineHeight: 1.4
                    color: "#d7e3ec"
                    text: root.titleText.toUpperCase()
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 64
                    font.family: root.fontFamily
                    font.pixelSize: 18
                    font.letterSpacing: 5
                    color: "#7ba7d9"
                    text: "CRYSTAL EDITION"
                }
            }

            // BACK fallback: a deliberate Crystal back-cover composition.
            // Front art is used only as dimmed source material inside the
            // authored art window — the front cover never reappears as
            // the back cover. Title hierarchy sits in the guided zones.
            Item {
                anchors.fill: parent
                visible: root.backComposed
                Image {
                    id: backAccentArt
                    x: 48; y: 48; width: 532; height: 320
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true
                    opacity: 0.5
                    source: root.frontArt
                    visible: source !== "" && status === Image.Ready
                }
                Rectangle {
                    x: 48; y: 48; width: 532; height: 320
                    color: "#16304a"
                    visible: !backAccentArt.visible
                }
                Image {
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    asynchronous: true
                    source: root.assetBase + "case-back-fallback.svg"
                }
                Text {
                    x: 48; y: 486
                    width: 532
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    maximumLineCount: 3
                    font.family: root.fontFamily
                    font.pixelSize: 42
                    font.letterSpacing: 5
                    lineHeight: 1.35
                    color: "#d7e3ec"
                    text: root.titleText.toUpperCase()
                }
                Text {
                    x: 48; y: 824
                    font.family: root.fontFamily
                    font.pixelSize: 17
                    font.letterSpacing: 5
                    color: "#7ba7d9"
                    text: "CRYSTAL EDITION"
                }
            }

            // designed fallback spine: narrow band, vertical title
            Item {
                anchors.fill: parent
                visible: root.isSpine && root.spineArt === ""
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#1b2a40" }
                        GradientStop { position: 1.0; color: "#101a2a" }
                    }
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 40; width: 26; height: 26
                    color: "#7ba7d9"
                    opacity: 0.8
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height - 66; width: 26; height: 26
                    color: "#7ba7d9"
                    opacity: 0.8
                }
                Text {
                    width: parent.height - 160
                    height: parent.width
                    anchors.centerIn: parent
                    rotation: -90
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    font.family: root.fontFamily
                    font.pixelSize: 30
                    font.letterSpacing: 4
                    color: "#d7e3ec"
                    text: MT.spineText(root.titleText)
                }
            }
        }

        // authored case: draws the keep case AROUND the art window
        Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            source: root.assetBase + (root.isSpine ? "case-spine.svg"
                : (root.view === "back" ? "case-back.svg" : "case-front.svg"))
        }
    }

    // ---- OPEN: composed spread (interior + hinge + tray + disc) ----
    Item {
        anchors.fill: parent
        visible: root.isOpen

        // authored open-case base: panels, hinge barrels, tray, hub post
        Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            source: root.assetBase + "case-open.svg"
        }

        // authored case interior: moulded panel, booklet retaining
        // clips, ribs, debossed manual well — a real inside of the
        // case. Exterior cover art is never wallpapered in here; QML
        // adds only a small etched-feel title.
        Item {
            x: MT.PS2.innerX; y: MT.PS2.innerY
            width: MT.PS2.innerW; height: MT.PS2.innerH
            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true
                source: root.assetBase + "case-interior.svg"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 52
                width: parent.width - 140
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.family: root.fontFamily
                font.pixelSize: 23
                font.letterSpacing: 6
                color: "#d7e3ec"
                opacity: 0.5
                text: root.titleText.toUpperCase()
            }
        }

        // the disc: game texture under the authored disc template.
        // Lifts off the hub post for the launch transition.
        Item {
            id: discGroup
            x: MT.PS2.discX - MT.PS2.discD / 2
            y: MT.PS2.discY - MT.PS2.discD / 2 + (root.lifting ? -230 : 0)
            width: MT.PS2.discD
            height: MT.PS2.discD
            transformOrigin: Item.Center
            scale: root.lifting ? 1.03 : 1
            Behavior on y {
                NumberAnimation { duration: 420; easing.type: Easing.OutQuad }
            }
            Behavior on scale {
                NumberAnimation { duration: 420; easing.type: Easing.OutQuad }
            }

            // disc artwork composite — invisible; rendered only through
            // the circular mask below. Real scans, art-derived faces and
            // the designed fallback share this one clipping path.
            Item {
                id: discArtSource
                anchors.fill: parent
                visible: false
                Rectangle {
                    anchors.fill: parent
                    color: "#9fb4c9"   // disc backing: visible only if art fails
                }
                // "scan": genuine disc artwork
                Image {
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true
                    source: root.discKind === "scan" ? root.discArt : ""
                    visible: source !== "" && status === Image.Ready
                }
                // "art": cover art under the disc treatment
                Image {
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true
                    opacity: 0.92
                    source: root.discKind === "art" ? root.frontArt : ""
                    visible: source !== "" && status === Image.Ready
                }
                // "none": designed disc face — tonal, ringed, titled
                Item {
                    anchors.fill: parent
                    visible: root.discKind === "none"
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#e6eef6" }
                            GradientStop { position: 1.0; color: "#a9bfd4" }
                        }
                    }
                    Repeater {
                        model: 3
                        Rectangle {
                            width: 300 + index * 70
                            height: 300 + index * 70
                            radius: width / 2
                            anchors.centerIn: parent
                            color: "transparent"
                            border.width: 2
                            border.color: "#ffffff"
                            opacity: 0.28
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: parent.height * 0.72
                        width: parent.width * 0.7
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        font.family: root.fontFamily
                        font.pixelSize: 26
                        font.letterSpacing: 4
                        color: "#24344a"
                        text: root.titleText.toUpperCase()
                    }
                }
            }

            // genuine circular mask: artwork can never show outside the
            // disc boundary — no square corners, ever. One masked item
            // is cheap; no per-frame Canvas work.
            OpacityMask {
                anchors.fill: parent
                source: discArtSource
                maskSource: Image {
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    asynchronous: true
                    source: root.assetBase + "disc-mask.svg"
                }
            }

            // authored disc template: hub, sheen, edge — over the art
            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true
                source: root.assetBase + "disc.svg"
            }
        }
    }

    Component.onCompleted: viewDip.restart()
}
