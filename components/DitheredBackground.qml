import QtQuick
import QtQuick.Effects

Item {
  id: root

  property bool bgEnabled: false
  property string imagePath: ""
  property real blurAmount: 0.2
  property bool ditherEnabled: true
  property real ditherIntensity: 0.5
  property real colorLevels: 2.0
  property real cellSize: 2.0
  property real adaptiveDim: 0.65
  property real dimOpacity: 0.4
  property color dimColor: "#000000"
  property real radius: 14.0
  property bool vignetteEnabled: true
  property real topFadeExtent: 0.22
  property real bottomFadeExtent: 0.20
  property real vignetteSoftness: 1.0

  visible: root.bgEnabled && root.resolvedSource !== ""
  clip: true

  readonly property string resolvedSource: {
    if (!root.imagePath || root.imagePath.trim() === "") return ""
    var p = root.imagePath.trim()
    if (p.indexOf("://") !== -1) return p
    if (p.startsWith("/")) return "file://" + p
    return Qt.resolvedUrl(p)
  }

  // FBO Layer cache: Render shaders once into an offscreen texture to guarantee
  // zero ongoing GPU overhead while typing at 144Hz+.
  layer.enabled: true
  layer.smooth: true

  // Solid base matching the Omarchy clean menu background
  Rectangle {
    id: baseSolid
    anchors.fill: parent
    color: root.dimColor
    radius: root.radius
  }

  // Raw source image (texture captured by ShaderEffectSource)
  Image {
    id: rawImg
    anchors.fill: parent
    source: root.resolvedSource
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: true
    smooth: true
    visible: false
  }

  // Hardware-accelerated blur via QtQuick.Effects
  MultiEffect {
    id: blurEffect
    anchors.fill: parent
    source: rawImg
    blurEnabled: root.blurAmount > 0.0
    blur: Math.min(1.0, Math.max(0.0, root.blurAmount))
    blurMax: 32
    visible: false
  }

  // Texture provider: makes the offscreen source item available as a GPU sampler
  ShaderEffectSource {
    id: textureSource
    anchors.fill: parent
    sourceItem: root.blurAmount > 0.0 ? blurEffect : rawImg
    hideSource: true
    live: true
    visible: false
  }

  // Custom Bayer 8x8 ordered dithering + quantization + SDF rounded corner shader
  ShaderEffect {
    id: ditherEffect
    anchors.fill: parent
    visible: true

    property var source: textureSource
    property real ditherIntensity: Math.min(1.0, Math.max(0.0, root.ditherIntensity))
    property real colorLevels: Math.min(64.0, Math.max(2.0, root.colorLevels))
    property real ditherEnabled: root.ditherEnabled ? 1.0 : 0.0
    property real vignetteEnabled: root.vignetteEnabled ? 1.0 : 0.0
    property real itemWidth: root.width
    property real itemHeight: root.height
    property real cornerRadius: root.radius
    property real cellSize: Math.max(1.0, root.cellSize)
    property real adaptiveDim: Math.min(1.0, Math.max(0.0, root.adaptiveDim))

    fragmentShader: Qt.resolvedUrl("../shaders/dither.frag.qsb")
  }

  // Scrim / Dimming layer to preserve high text contrast and readability
  Rectangle {
    anchors.fill: parent
    color: root.dimColor
    opacity: Math.min(1.0, Math.max(0.0, root.dimOpacity))
    radius: root.radius
  }
}
