import QtQuick

ShaderEffect {
  id: root

  // direction: 0.0 = top-down (header: solid at top, dissolves down)
  //            1.0 = bottom-up (footer: solid at bottom, dissolves up)
  property real direction: 0.0
  property real cellSize: 2.0
  property real maxAlpha: 0.96
  property real minAlpha: 0.0
  property real ditherIntensity: 1.0
  property color color: "#0e1015"
  property real solidSpan: 0.45
  property real cornerRadius: 0.0
  property real itemWidth: root.width
  property real itemHeight: root.height

  property real colorR: root.color.r
  property real colorG: root.color.g
  property real colorB: root.color.b

  fragmentShader: Qt.resolvedUrl("../shaders/dither_scrim.frag.qsb")
}
