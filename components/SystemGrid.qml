import QtQuick 2.12

// 3x3 system grid, populated dynamically from api.collections.
// Paging: collections are chunked into pages of 9. D-pad movement at a grid
// edge advances to the adjacent page when one exists, otherwise wraps
// predictably within the current page.
Item {
    id: root

    property int pageSize: 9
    property int columns: 3
    property int page: 0
    property int currentIndex: 0   // index within the current page

    readonly property int totalCount: api.collections.count
    readonly property int pageCount: Math.max(1, Math.ceil(totalCount / pageSize))
    readonly property int pageItemCount: Math.max(0, Math.min(pageSize, totalCount - page * pageSize))
    readonly property int globalIndex: page * pageSize + currentIndex

    property string fontFamily: "monospace"

    function row() { return Math.floor(currentIndex / columns) }
    function col() { return currentIndex % columns }

    function clampIndex(i) { return Math.max(0, Math.min(pageItemCount - 1, i)) }

    function moveLeft() {
        if (pageItemCount === 0) return
        if (col() > 0) {
            currentIndex--
        } else if (page > 0) {
            page--
            currentIndex = clampIndex(row() * columns + (columns - 1))
        } else {
            currentIndex = clampIndex(row() * columns + (columns - 1)) // wrap row
        }
    }

    function moveRight() {
        if (pageItemCount === 0) return
        if (col() < columns - 1 && currentIndex + 1 < pageItemCount) {
            currentIndex++
        } else if (page < pageCount - 1) {
            page++
            currentIndex = clampIndex(row() * columns)
        } else {
            currentIndex = row() * columns // wrap row
        }
    }

    function moveUp() {
        if (pageItemCount === 0) return
        if (row() > 0) {
            currentIndex = clampIndex(currentIndex - columns)
        } else {
            // wrap to the last row, same column
            var t = col()
            while (t + columns < pageItemCount) t += columns
            currentIndex = t
        }
    }

    function moveDown() {
        if (pageItemCount === 0) return
        if (currentIndex + columns < pageItemCount) {
            currentIndex += columns
        } else {
            currentIndex = clampIndex(col()) // wrap to first row, same column
        }
    }

    function jumpTo(globalIdx) {
        if (globalIdx < 0 || globalIdx >= totalCount) return
        page = Math.floor(globalIdx / pageSize)
        currentIndex = globalIdx % pageSize
    }

    function currentCollection() {
        if (globalIndex < 0 || globalIndex >= totalCount) return null
        return api.collections.get(globalIndex)
    }

    Grid {
        id: gridLayout
        columns: root.columns
        rows: 3
        columnSpacing: 28
        rowSpacing: 28
        anchors.horizontalCenter: parent.horizontalCenter
        // Top-align to where a full 3-row grid would start when centered,
        // so partial last pages don't float vertically centered.
        anchors.top: parent.top
        anchors.topMargin: Math.max(0, (parent.height - (3 * cellH + 2 * rowSpacing)) / 2)

        property real cellW: (root.width - (columns - 1) * columnSpacing) / columns
        property real cellH: (root.height - (rows - 1) * rowSpacing) / rows

        Repeater {
            model: root.pageItemCount
            delegate: SystemTile {
                width: gridLayout.cellW
                height: gridLayout.cellH
                fontFamily: root.fontFamily
                selected: index === root.currentIndex

                property var coll: api.collections.get(root.page * root.pageSize + index)
                shortName: coll ? (coll.shortName || "") : ""
                label: {
                    if (!coll) return ""
                    var s = coll.shortName || coll.name || ""
                    return s.toUpperCase()
                }
            }
        }
    }
}
