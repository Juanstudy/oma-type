import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Minimalist, high-contrast in-body settings view (Monkeytype & Omarchy-inspired).
// Renders on a solid, opaque tactile surface plate that eliminates dither noise
// bleed, organized into structured category cards with cohesive proportions.
Item {
  id: panel

  // ---------------------------------------------------- Public API
  property bool open: false

  // One-way bindings from overlay root
  property string mode: "quote"
  property string quoteLength: "short"
  property int duration: 15
  property int wordCount: 25
  property string language: "english"
  property bool punctuation: false
  property bool numbers: false
  property string soundTheme: "thock"
  property double soundVolume: 0.55
  property bool bgImageEnabled: false
  property string bgImagePath: ""
  property double bgBlur: 0.04
  property bool bgDither: true
  property double bgDitherIntensity: 1
  property double bgColorLevels: 2
  property double bgCellSize: 2
  property double bgDim: 0.4
  property double bgAdaptiveDim: 0.65
  property bool bgVignette: false
  property bool bgAdaptiveAccent: true
  property color themeAccent: Commons.Color.menu.selectedText

  // Category navigation state
  property string activeCategory: "typing" // "typing" | "sound" | "appearance"

  // Live value updates
  signal settingsChanged(string key, var value)
  // Persist request
  signal settingsCommit()
  signal closeRequested()
  signal focusReleased()
  signal openFilePickerRequested()

  function commit() {
    panel.settingsCommit()
  }

  anchors.fill: parent
  opacity: panel.open ? 1.0 : 0.0
  visible: opacity > 0.01

  Behavior on opacity {
    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
  }

  onOpenChanged: {
    if (panel.open) {
      panelFlickable.contentY = 0
      panel.focusReleased()
    }
  }

  onActiveCategoryChanged: {
    panelFlickable.contentY = 0
  }

  // ---------------------------------------------------- High-Contrast Solid Surface
  // 100% opaque surface blocks high-frequency wallpaper dither noise completely,
  // ensuring crisp font rendering and perfect readability.
  Rectangle {
    id: surfacePlate
    anchors.fill: parent
    radius: 14
    color: Commons.Color.menu.background
    border.color: Util.alpha(Commons.Color.menu.text, 0.16)
    border.width: 1
    clip: true

    // Click-away keyboard focus release
    MouseArea {
      anchors.fill: parent
      z: -1
      onClicked: panel.focusReleased()
    }

    // Top Category Navigation Bar
    Item {
      id: categoryBar
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      height: 48

      Row {
        anchors.centerIn: parent
        spacing: 10

        CategoryChip {
          label: "typing"
          active: panel.activeCategory === "typing"
          onClicked: panel.activeCategory = "typing"
        }

        OutlinedText {
          anchors.verticalCenter: parent.verticalCenter
          text: "·"
          font.family: Style.font.family
          font.pixelSize: 13
          color: Util.alpha(Commons.Color.menu.text, 0.25)
        }

        CategoryChip {
          label: "sound"
          active: panel.activeCategory === "sound"
          onClicked: panel.activeCategory = "sound"
        }

        OutlinedText {
          anchors.verticalCenter: parent.verticalCenter
          text: "·"
          font.family: Style.font.family
          font.pixelSize: 13
          color: Util.alpha(Commons.Color.menu.text, 0.25)
        }

        CategoryChip {
          label: "appearance"
          active: panel.activeCategory === "appearance"
          onClicked: panel.activeCategory = "appearance"
        }
      }

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Util.alpha(Commons.Color.menu.text, 0.1)
      }
    }

    // Scrollable Content
    Item {
      id: contentArea
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: categoryBar.bottom
      anchors.bottom: parent.bottom

      // Top dither dissolve
      DitheredScrim {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 20
        direction: 0.0
        cellSize: panel.bgCellSize
        ditherIntensity: panel.bgDither ? 1.0 : 0.0
        color: Commons.Color.menu.background
        maxAlpha: 1.0
        minAlpha: 0.0
        solidSpan: 0.15
        z: 10
      }

      // Bottom dither dissolve
      DitheredScrim {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 20
        direction: 1.0
        cellSize: panel.bgCellSize
        ditherIntensity: panel.bgDither ? 1.0 : 0.0
        color: Commons.Color.menu.background
        maxAlpha: 1.0
        minAlpha: 0.0
        solidSpan: 0.15
        cornerRadius: surfacePlate.radius
        z: 10
      }

      Flickable {
        id: panelFlickable
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: activeColumnContainer.height + 40
        boundsBehavior: Flickable.StopAtBounds

        // Content centered at 620px for optimal spatial harmony
        Item {
          id: activeColumnContainer
          anchors.horizontalCenter: parent.horizontalCenter
          y: 16
          width: Math.min(620, panelFlickable.width - 32)
          height: {
            if (panel.activeCategory === "typing") return typingColumn.height
            if (panel.activeCategory === "sound") return soundColumn.height
            return appearanceColumn.height
          }

          // ================================================================
          // 1. TYPING CATEGORY
          // ================================================================
          Column {
            id: typingColumn
            x: 0
            y: 0
            width: parent.width
            spacing: 16
            visible: panel.activeCategory === "typing"

            SettingCard {
              title: "MODE & CRITERIA"

              SettingRow {
                label: "mode"
                description: "typing test discipline"
                showDivider: true
                SegOptions {
                  labels: ["quote", "time", "words"]
                  values: ["quote", "time", "words"]
                  current: panel.mode
                  onChosen: function(val) { panel.settingsChanged("mode", val); panel.commit() }
                }
              }

              SettingRow {
                visible: panel.mode === "quote"
                label: "quote length"
                description: "target quote size from quote database"
                showDivider: true
                SegOptions {
                  labels: ["short", "medium"]
                  values: ["short", "medium"]
                  current: panel.quoteLength
                  onChosen: function(val) { panel.settingsChanged("quoteLength", val); panel.commit() }
                }
              }

              SettingRow {
                visible: panel.mode === "time"
                label: "duration"
                description: "countdown duration in seconds"
                showDivider: true
                SegOptions {
                  labels: ["15s", "30s", "60s"]
                  values: ["15", "30", "60"]
                  current: String(panel.duration)
                  onChosen: function(val) { panel.settingsChanged("duration", Number(val)); panel.commit() }
                }
              }

              SettingRow {
                visible: panel.mode === "words"
                label: "word target"
                description: "total words to complete"
                showDivider: true
                SegOptions {
                  labels: ["10", "25", "50", "100"]
                  values: ["10", "25", "50", "100"]
                  current: String(panel.wordCount)
                  onChosen: function(val) { panel.settingsChanged("wordCount", Number(val)); panel.commit() }
                }
              }

              SettingRow {
                label: "language"
                description: "vocabulary database for words & quotes"
                showDivider: false
                SegOptions {
                  labels: ["english", "español"]
                  values: ["english", "spanish"]
                  current: panel.language
                  onChosen: function(val) { panel.settingsChanged("language", val); panel.commit() }
                }
              }
            }

            SettingCard {
              title: "RULES & MODIFIERS"

              SettingRow {
                label: "punctuation"
                description: "require commas, periods, quotes and symbols"
                showDivider: true
                TextToggle {
                  checked: panel.punctuation
                  onToggled: function(c) { panel.settingsChanged("punctuation", c); panel.commit() }
                }
              }

              SettingRow {
                label: "numbers"
                description: "mix numeric digits into word sequence"
                showDivider: false
                TextToggle {
                  checked: panel.numbers
                  onToggled: function(c) { panel.settingsChanged("numbers", c); panel.commit() }
                }
              }
            }
          }

          // ================================================================
          // 2. SOUND CATEGORY
          // ================================================================
          Column {
            id: soundColumn
            x: 0
            y: 0
            width: parent.width
            spacing: 16
            visible: panel.activeCategory === "sound"

            SettingCard {
              title: "MECHANICAL ACOUSTICS"

              SettingRow {
                label: "key theme"
                description: "switch audio feedback synthesis"
                showDivider: true
                SegOptions {
                  labels: ["thock", "click", "typewriter", "off"]
                  values: ["thock", "click", "typewriter", "off"]
                  current: panel.soundTheme
                  onChosen: function(val) { panel.settingsChanged("soundTheme", val); panel.commit() }
                }
              }

              SettingRow {
                label: "volume"
                description: "playback gain level"
                showDivider: false
                SliderControl {
                  percent: true
                  value: panel.soundVolume
                  onChanged: function(val) { panel.settingsChanged("soundVolume", val) }
                  onCommitted: panel.commit()
                }
              }
            }
          }

          // ================================================================
          // 3. APPEARANCE CATEGORY
          // ================================================================
          Column {
            id: appearanceColumn
            x: 0
            y: 0
            width: parent.width
            spacing: 16
            visible: panel.activeCategory === "appearance"

            SettingCard {
              title: "WALLPAPER BACKDROP"

              SettingRow {
                label: "image backdrop"
                description: "render image or video underneath overlay"
                showDivider: true
                TextToggle {
                  checked: panel.bgImageEnabled
                  onToggled: function(c) { panel.settingsChanged("bgImageEnabled", c); panel.commit() }
                }
              }

              SettingRow {
                label: "image path"
                description: "absolute path to background image"
                showDivider: true
                PathControl {
                  path: panel.bgImagePath
                  onPathEntered: function(newPath) {
                    panel.settingsChanged("bgImagePath", newPath)
                    panel.commit()
                  }
                  onBrowseClicked: panel.openFilePickerRequested()
                }
              }

              SettingRow {
                label: "pre-filter blur"
                description: "gaussian blur radius before rasterization"
                showDivider: false
                SliderControl {
                  percent: true
                  value: panel.bgBlur
                  onChanged: function(val) { panel.settingsChanged("bgBlur", val) }
                  onCommitted: panel.commit()
                }
              }
            }

            SettingCard {
              title: "BAYER DITHERING PIPELINE"

              SettingRow {
                label: "dither effect"
                description: "ordered 8x8 matrix dithering shader"
                showDivider: true
                TextToggle {
                  checked: panel.bgDither
                  onToggled: function(c) { panel.settingsChanged("bgDither", c); panel.commit() }
                }
              }

              SettingRow {
                label: "dither intensity"
                description: "blend ratio between raw image and dithered raster"
                showDivider: true
                SliderControl {
                  percent: true
                  value: panel.bgDitherIntensity
                  onChanged: function(val) { panel.settingsChanged("bgDitherIntensity", val) }
                  onCommitted: panel.commit()
                }
              }

              SettingRow {
                label: "color levels"
                description: "quantization steps per channel (2 = 1-bit monochrome)"
                showDivider: true
                StepperControl {
                  min: 2
                  max: 16
                  value: Math.round(panel.bgColorLevels)
                  onChanged: function(val) { panel.settingsChanged("bgColorLevels", val) }
                  onCommitted: panel.commit()
                }
              }

              SettingRow {
                label: "cell size"
                description: "dither pixelation scale grid (1 = native, 6 = chunky retro)"
                showDivider: false
                StepperControl {
                  min: 1
                  max: 6
                  value: Math.round(panel.bgCellSize)
                  onChanged: function(val) { panel.settingsChanged("bgCellSize", val) }
                  onCommitted: panel.commit()
                }
              }
            }

            SettingCard {
              title: "LIGHTING & HARMONIZATION"

              SettingRow {
                label: "static dim"
                description: "base darkening scrim over wallpaper"
                showDivider: true
                SliderControl {
                  percent: true
                  value: panel.bgDim
                  onChanged: function(val) { panel.settingsChanged("bgDim", val) }
                  onCommitted: panel.commit()
                }
              }

              SettingRow {
                label: "adaptive luma dim"
                description: "dynamically darkens bright wallpapers to protect contrast"
                showDivider: true
                SliderControl {
                  percent: true
                  value: panel.bgAdaptiveDim
                  onChanged: function(val) { panel.settingsChanged("bgAdaptiveDim", val) }
                  onCommitted: panel.commit()
                }
              }

              SettingRow {
                label: "vignette"
                description: "dark perimeter edge gradient around the card"
                showDivider: true
                TextToggle {
                  checked: panel.bgVignette
                  onToggled: function(c) { panel.settingsChanged("bgVignette", c); panel.commit() }
                }
              }

              SettingRow {
                label: "adaptive accent"
                description: "harmonize highlights with dominant wallpaper palette"
                showDivider: false
                TextToggle {
                  checked: panel.bgAdaptiveAccent
                  onToggled: function(c) { panel.settingsChanged("bgAdaptiveAccent", c); panel.commit() }
                }
              }
            }
          }
        }
      }
    }
  }

  // ========================================================================
  // REUSABLE TACTILE COMPONENTS
  // ========================================================================

  // Structured Card grouping related settings with accent heading
  component SettingCard: Column {
    id: sCard
    width: parent.width
    spacing: 8
    property string title: ""
    default property alias rows: cardBody.data

    Row {
      spacing: 8
      anchors.left: parent.left
      anchors.leftMargin: 4

      Rectangle {
        width: 3
        height: 12
        radius: 1.5
        color: panel.themeAccent
        anchors.verticalCenter: parent.verticalCenter
      }

      OutlinedText {
        text: sCard.title
        font.family: Style.font.family
        font.pixelSize: 11
        font.bold: true
        color: panel.themeAccent
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Rectangle {
      width: parent.width
      radius: 10
      color: Util.alpha(Commons.Color.menu.text, 0.035)
      border.color: Util.alpha(Commons.Color.menu.text, 0.12)
      border.width: 1
      clip: true
      implicitHeight: cardBody.implicitHeight

      Column {
        id: cardBody
        width: parent.width
      }
    }
  }

  // Category Selector Chip
  component CategoryChip: Rectangle {
    id: cChip
    property string label: ""
    property bool active: false
    signal clicked()

    height: 28
    width: cChipText.contentWidth + 20
    radius: 7
    color: active
      ? Util.alpha(panel.themeAccent, 0.22)
      : (chipM.containsMouse ? Util.alpha(Commons.Color.menu.text, 0.08) : "transparent")
    border.color: active
      ? Util.alpha(panel.themeAccent, 0.6)
      : (chipM.containsMouse ? Util.alpha(Commons.Color.menu.text, 0.2) : "transparent")
    border.width: 1

    Behavior on color { ColorAnimation { duration: 100 } }
    Behavior on border.color { ColorAnimation { duration: 100 } }

    OutlinedText {
      id: cChipText
      anchors.centerIn: parent
      text: cChip.label
      font.family: Style.font.family
      font.pixelSize: 12
      font.bold: cChip.active
      color: cChip.active ? panel.themeAccent : Util.alpha(Commons.Color.menu.text, 0.65)
    }

    MouseArea {
      id: chipM
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: cChip.clicked()
    }
  }

  // Structured Tactile Setting Row
  component SettingRow: Rectangle {
    id: rowItem
    default property alias control: controlContainer.data
    property string label: ""
    property string description: ""
    property bool showDivider: true

    width: parent.width
    height: 50
    color: rowMouse.containsMouse ? Util.alpha(Commons.Color.menu.text, 0.05) : "transparent"

    Behavior on color { ColorAnimation { duration: 100 } }

    MouseArea {
      id: rowMouse
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.NoButton
    }

    // Left info
    Column {
      anchors.left: parent.left
      anchors.leftMargin: 14
      anchors.right: controlContainer.left
      anchors.rightMargin: 16
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      OutlinedText {
        text: rowItem.label
        font.family: Style.font.family
        font.pixelSize: 13
        font.bold: true
        color: Commons.Color.menu.text
      }

      OutlinedText {
        text: rowItem.description
        font.family: Style.font.family
        font.pixelSize: 11
        color: Util.alpha(Commons.Color.menu.text, 0.65)
        elide: Text.ElideRight
        width: parent.width
      }
    }

    // Right control slot
    Item {
      id: controlContainer
      anchors.right: parent.right
      anchors.rightMargin: 14
      anchors.verticalCenter: parent.verticalCenter
      height: parent.height
      width: childrenRect.width
    }

    // Subtle divider line between rows
    Rectangle {
      visible: rowItem.showDivider
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.leftMargin: 14
      anchors.rightMargin: 14
      anchors.bottom: parent.bottom
      height: 1
      color: Util.alpha(Commons.Color.menu.text, 0.06)
    }
  }

  // Segmented Options (Clean inline chips)
  component SegOptions: Row {
    id: segRow
    anchors.verticalCenter: parent.verticalCenter
    spacing: 6

    property var labels: []
    property var values: []
    property string current: ""
    signal chosen(var value)

    Repeater {
      model: segRow.labels.length

      delegate: Rectangle {
        id: optChip
        property string chipLabel: segRow.labels[index]
        property var chipValue: segRow.values[index]
        readonly property bool isSelected: String(segRow.current) === String(chipValue)

        height: 28
        width: optText.contentWidth + 16
        radius: 6
        color: isSelected
          ? Util.alpha(panel.themeAccent, 0.24)
          : (optMouse.containsMouse ? Util.alpha(Commons.Color.menu.text, 0.1) : Util.alpha(Commons.Color.menu.text, 0.05))
        border.color: isSelected ? Util.alpha(panel.themeAccent, 0.7) : Util.alpha(Commons.Color.menu.text, 0.14)
        border.width: 1

        OutlinedText {
          id: optText
          anchors.centerIn: parent
          text: optChip.chipLabel
          font.family: Style.font.family
          font.pixelSize: 11
          font.bold: optChip.isSelected
          color: optChip.isSelected ? panel.themeAccent : Util.alpha(Commons.Color.menu.text, 0.7)
        }

        MouseArea {
          id: optMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: segRow.chosen(optChip.chipValue)
        }
      }
    }
  }

  // Minimalist Text Toggle [ off | on ]
  component TextToggle: Rectangle {
    id: tToggle
    property bool checked: false
    signal toggled(bool checked)

    anchors.verticalCenter: parent.verticalCenter
    height: 28
    width: 84
    radius: 6
    color: Util.alpha(Commons.Color.menu.text, 0.05)
    border.color: Util.alpha(Commons.Color.menu.text, 0.14)
    border.width: 1

    Row {
      anchors.fill: parent
      anchors.margins: 2
      spacing: 2

      Rectangle {
        width: (parent.width - 2) / 2
        height: parent.height
        radius: 4
        color: !tToggle.checked ? Util.alpha(Commons.Color.menu.text, 0.14) : "transparent"
        border.color: !tToggle.checked ? Util.alpha(Commons.Color.menu.text, 0.22) : "transparent"
        border.width: 1

        OutlinedText {
          anchors.centerIn: parent
          text: "off"
          font.family: Style.font.family
          font.pixelSize: 11
          font.bold: !tToggle.checked
          color: !tToggle.checked ? Commons.Color.menu.text : Util.alpha(Commons.Color.menu.text, 0.4)
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: if (tToggle.checked) tToggle.toggled(false)
        }
      }

      Rectangle {
        width: (parent.width - 2) / 2
        height: parent.height
        radius: 4
        color: tToggle.checked ? Util.alpha(panel.themeAccent, 0.25) : "transparent"
        border.color: tToggle.checked ? Util.alpha(panel.themeAccent, 0.7) : "transparent"
        border.width: 1

        OutlinedText {
          anchors.centerIn: parent
          text: "on"
          font.family: Style.font.family
          font.pixelSize: 11
          font.bold: tToggle.checked
          color: tToggle.checked ? panel.themeAccent : Util.alpha(Commons.Color.menu.text, 0.4)
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: if (!tToggle.checked) tToggle.toggled(true)
        }
      }
    }
  }

  // Sleek Slider with Percentage Badge
  component SliderControl: Row {
    id: sControl
    anchors.verticalCenter: parent.verticalCenter
    spacing: 10

    property double value: 0.0
    property bool percent: false
    signal changed(double val)
    signal committed()

    Item {
      id: trackBox
      width: 120
      height: 28
      anchors.verticalCenter: parent.verticalCenter

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 4
        radius: 2
        color: Util.alpha(Commons.Color.menu.text, 0.16)

        Rectangle {
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          width: Math.max(0, Math.min(parent.width, sControl.value * parent.width))
          radius: 2
          color: panel.themeAccent
        }
      }

      Rectangle {
        id: thumb
        x: Math.max(0, Math.min(trackBox.width - width, (sControl.value * (trackBox.width - width))))
        anchors.verticalCenter: parent.verticalCenter
        width: 14
        height: 14
        radius: 7
        color: dragMouse.containsMouse ? panel.themeAccent : Commons.Color.menu.text
        border.color: panel.themeAccent
        border.width: 1.5

        Behavior on color { ColorAnimation { duration: 80 } }
      }

      MouseArea {
        id: dragMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function updateFromMouse(mouseX) {
          var norm = Math.max(0.0, Math.min(1.0, (mouseX - thumb.width / 2) / (trackBox.width - thumb.width)))
          sControl.changed(norm)
        }

        onPositionChanged: function(mouse) {
          if (pressed) updateFromMouse(mouse.x)
        }
        onPressed: function(mouse) { updateFromMouse(mouse.x) }
        onReleased: sControl.committed()
      }
    }

    OutlinedText {
      anchors.verticalCenter: parent.verticalCenter
      text: sControl.percent ? Math.round(sControl.value * 100) + "%" : sControl.value.toFixed(2)
      font.family: Style.font.family
      font.pixelSize: 11
      font.bold: true
      color: Commons.Color.menu.text
      width: 36
      horizontalAlignment: Text.AlignRight
    }
  }

  // Stepper Control [ − ]  Val  [ + ]
  component StepperControl: Row {
    id: stepControl
    anchors.verticalCenter: parent.verticalCenter
    spacing: 6

    property int value: 1
    property int min: 1
    property int max: 10
    signal changed(int val)
    signal committed()

    Rectangle {
      width: 26
      height: 26
      radius: 6
      anchors.verticalCenter: parent.verticalCenter
      color: minusM.containsMouse ? Util.alpha(Commons.Color.menu.text, 0.12) : Util.alpha(Commons.Color.menu.text, 0.05)
      border.color: Util.alpha(Commons.Color.menu.text, 0.15)
      border.width: 1

      OutlinedText {
        anchors.centerIn: parent
        text: "−"
        font.family: Style.font.family
        font.pixelSize: 13
        font.bold: true
        color: Commons.Color.menu.text
      }

      MouseArea {
        id: minusM
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          if (stepControl.value > stepControl.min) {
            stepControl.changed(stepControl.value - 1)
            stepControl.committed()
          }
        }
      }
    }

    OutlinedText {
      anchors.verticalCenter: parent.verticalCenter
      text: String(stepControl.value)
      font.family: Style.font.family
      font.pixelSize: 12
      font.bold: true
      color: panel.themeAccent
      width: 24
      horizontalAlignment: Text.AlignHCenter
    }

    Rectangle {
      width: 26
      height: 26
      radius: 6
      anchors.verticalCenter: parent.verticalCenter
      color: plusM.containsMouse ? Util.alpha(Commons.Color.menu.text, 0.12) : Util.alpha(Commons.Color.menu.text, 0.05)
      border.color: Util.alpha(Commons.Color.menu.text, 0.15)
      border.width: 1

      OutlinedText {
        anchors.centerIn: parent
        text: "+"
        font.family: Style.font.family
        font.pixelSize: 13
        font.bold: true
        color: Commons.Color.menu.text
      }

      MouseArea {
        id: plusM
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          if (stepControl.value < stepControl.max) {
            stepControl.changed(stepControl.value + 1)
            stepControl.committed()
          }
        }
      }
    }
  }

  // Path input with Browse button
  component PathControl: Row {
    id: pControl
    anchors.verticalCenter: parent.verticalCenter
    spacing: 8

    property string path: ""
    signal pathEntered(string newPath)
    signal browseClicked()

    Rectangle {
      width: 150
      height: 28
      radius: 6
      color: pathIn.activeFocus ? Util.alpha(Commons.Color.menu.text, 0.08) : Util.alpha(Commons.Color.menu.text, 0.04)
      border.color: pathIn.activeFocus ? Util.alpha(panel.themeAccent, 0.6) : Util.alpha(Commons.Color.menu.text, 0.14)
      border.width: 1

      TextInput {
        id: pathIn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        text: pControl.path
        color: Commons.Color.menu.text
        font.family: Style.font.family
        font.pixelSize: 11
        clip: true
        cursorVisible: activeFocus
        selectionColor: Util.alpha(panel.themeAccent, 0.4)

        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          visible: pathIn.text === "" && !pathIn.activeFocus
          text: "image path..."
          font.family: Style.font.family
          font.pixelSize: 11
          color: Util.alpha(Commons.Color.menu.text, 0.3)
        }

        onEditingFinished: {
          pControl.pathEntered(pathIn.text)
        }

        Keys.onEscapePressed: function(event) {
          pathIn.text = pControl.path
          panel.focusReleased()
          event.accepted = true
        }
      }
    }

    Rectangle {
      id: browseBtn
      width: 74
      height: 28
      radius: 6
      color: bMouse.containsMouse
        ? Util.alpha(panel.themeAccent, 0.24)
        : Util.alpha(Commons.Color.menu.text, 0.06)
      border.color: bMouse.containsMouse
        ? Util.alpha(panel.themeAccent, 0.6)
        : Util.alpha(Commons.Color.menu.text, 0.14)
      border.width: 1

      Row {
        anchors.centerIn: parent
        spacing: 4

        OutlinedText {
          text: "📁"
          font.pixelSize: 11
          anchors.verticalCenter: parent.verticalCenter
        }

        OutlinedText {
          text: "Browse"
          font.family: Style.font.family
          font.pixelSize: 10
          font.bold: true
          color: bMouse.containsMouse ? panel.themeAccent : Commons.Color.menu.text
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      MouseArea {
        id: bMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: pControl.browseClicked()
      }
    }
  }
}
