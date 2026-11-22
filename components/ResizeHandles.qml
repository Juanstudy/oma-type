import QtQuick

Item {
  id: root
  anchors.fill: parent
  z: 100
  visible: enabled

  property var targetCard
  property var overlay
  property bool resizing: false
  property real minWidth: 680
  property real minHeight: 420
  property real handleThickness: 8
  property real cornerSize: 16

  signal resizeCommitted()
  signal updateDimensions(real newW, real newH, real newOffX, real newOffY)

  function startResize(mouseArea, mouse, isLeft, isRight, isTop, isBottom) {
    if (!overlay || !targetCard) return
    var p = mouseArea.mapToItem(overlay, mouse.x, mouse.y)
    dragState.active = true
    dragState.isLeft = isLeft
    dragState.isRight = isRight
    dragState.isTop = isTop
    dragState.isBottom = isBottom
    dragState.startMouseX = p.x
    dragState.startMouseY = p.y
    dragState.startW = targetCard.width
    dragState.startH = targetCard.height
    dragState.startOffX = targetCard.cardOffsetX
    dragState.startOffY = targetCard.cardOffsetY
    root.resizing = true
  }

  function handleMove(mouseArea, mouse) {
    if (!dragState.active || !overlay || !targetCard) return
    var p = mouseArea.mapToItem(overlay, mouse.x, mouse.y)
    var dx = p.x - dragState.startMouseX
    var dy = p.y - dragState.startMouseY

    var newW = dragState.startW
    var newH = dragState.startH
    var newOffX = dragState.startOffX
    var newOffY = dragState.startOffY

    var maxW = overlay.width - 32
    var maxH = overlay.height - 32

    if (dragState.isRight) {
      newW = Math.max(root.minWidth, Math.min(maxW, dragState.startW + dx))
      newOffX = dragState.startOffX + (newW - dragState.startW) / 2
    } else if (dragState.isLeft) {
      newW = Math.max(root.minWidth, Math.min(maxW, dragState.startW - dx))
      newOffX = dragState.startOffX - (newW - dragState.startW) / 2
    }

    if (dragState.isBottom) {
      newH = Math.max(root.minHeight, Math.min(maxH, dragState.startH + dy))
      newOffY = dragState.startOffY + (newH - dragState.startH) / 2
    } else if (dragState.isTop) {
      newH = Math.max(root.minHeight, Math.min(maxH, dragState.startH - dy))
      newOffY = dragState.startOffY - (newH - dragState.startH) / 2
    }

    root.updateDimensions(newW, newH, newOffX, newOffY)
  }

  function endResize() {
    if (!dragState.active) return
    dragState.active = false
    root.resizing = false
    root.resizeCommitted()
  }

  QtObject {
    id: dragState
    property bool active: false
    property bool isLeft: false
    property bool isRight: false
    property bool isTop: false
    property bool isBottom: false
    property real startMouseX: 0
    property real startMouseY: 0
    property real startW: 0
    property real startH: 0
    property real startOffX: 0
    property real startOffY: 0
  }

  // ---- Edges ----
  MouseArea {
    id: topEdge
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: root.cornerSize
    anchors.rightMargin: root.cornerSize
    height: root.handleThickness
    cursorShape: Qt.SizeVerCursor
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onPressed: function(mouse) { root.startResize(topEdge, mouse, false, false, true, false) }
    onPositionChanged: function(mouse) { root.handleMove(topEdge, mouse) }
    onReleased: root.endResize()
    onCanceled: root.endResize()
  }

  MouseArea {
    id: bottomEdge
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: root.cornerSize
    anchors.rightMargin: root.cornerSize
    height: root.handleThickness
    cursorShape: Qt.SizeVerCursor
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onPressed: function(mouse) { root.startResize(bottomEdge, mouse, false, false, false, true) }
    onPositionChanged: function(mouse) { root.handleMove(bottomEdge, mouse) }
    onReleased: root.endResize()
    onCanceled: root.endResize()
  }

  MouseArea {
    id: leftEdge
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.topMargin: root.cornerSize
    anchors.bottomMargin: root.cornerSize
    width: root.handleThickness
    cursorShape: Qt.SizeHorCursor
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onPressed: function(mouse) { root.startResize(leftEdge, mouse, true, false, false, false) }
    onPositionChanged: function(mouse) { root.handleMove(leftEdge, mouse) }
    onReleased: root.endResize()
    onCanceled: root.endResize()
  }

  MouseArea {
    id: rightEdge
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.topMargin: root.cornerSize
    anchors.bottomMargin: root.cornerSize
    width: root.handleThickness
    cursorShape: Qt.SizeHorCursor
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onPressed: function(mouse) { root.startResize(rightEdge, mouse, false, true, false, false) }
    onPositionChanged: function(mouse) { root.handleMove(rightEdge, mouse) }
    onReleased: root.endResize()
    onCanceled: root.endResize()
  }

  // ---- Corners ----
  MouseArea {
    id: topLeftCorner
    anchors.top: parent.top
    anchors.left: parent.left
    width: root.cornerSize
    height: root.cornerSize
    cursorShape: Qt.SizeFDiagCursor
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onPressed: function(mouse) { root.startResize(topLeftCorner, mouse, true, false, true, false) }
    onPositionChanged: function(mouse) { root.handleMove(topLeftCorner, mouse) }
    onReleased: root.endResize()
    onCanceled: root.endResize()
  }

  MouseArea {
    id: topRightCorner
    anchors.top: parent.top
    anchors.right: parent.right
    width: root.cornerSize
    height: root.cornerSize
    cursorShape: Qt.SizeBDiagCursor
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onPressed: function(mouse) { root.startResize(topRightCorner, mouse, false, true, true, false) }
    onPositionChanged: function(mouse) { root.handleMove(topRightCorner, mouse) }
    onReleased: root.endResize()
    onCanceled: root.endResize()
  }

  MouseArea {
    id: bottomLeftCorner
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    width: root.cornerSize
    height: root.cornerSize
    cursorShape: Qt.SizeBDiagCursor
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onPressed: function(mouse) { root.startResize(bottomLeftCorner, mouse, true, false, false, true) }
    onPositionChanged: function(mouse) { root.handleMove(bottomLeftCorner, mouse) }
    onReleased: root.endResize()
    onCanceled: root.endResize()
  }

  MouseArea {
    id: bottomRightCorner
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    width: root.cornerSize
    height: root.cornerSize
    cursorShape: Qt.SizeFDiagCursor
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onPressed: function(mouse) { root.startResize(bottomRightCorner, mouse, false, true, false, true) }
    onPositionChanged: function(mouse) { root.handleMove(bottomRightCorner, mouse) }
    onReleased: root.endResize()
    onCanceled: root.endResize()
  }
}
