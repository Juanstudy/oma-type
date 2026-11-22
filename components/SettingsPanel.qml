import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Slide-in settings panel (Monkeytype-style) that lives inside the overlay's
// card body. Stateless regarding settings: every control binds to the parent
// root's properties and reports user intent through signals, so persistence
// flows through the existing root.saveSettings() path.
BorderSurface {
  id: panel

  // ---------------------------------------------------- Public API
  property bool open: false

  // One-way bindings from the overlay root (the panel never owns this state)
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

  // Live value updates (fired continuously while a slider drags)
  signal settingsChanged(string key, var value)
  // Persist request (fired once per discrete user action / drag release)
  signal settingsCommit()
  signal closeRequested()
  signal focusReleased()

  function commit() {
    panel.settingsCommit()
  }

  x: panel.open ? 0 : parent.width
  y: 0
  width: parent.width
  height: parent.height
  radius: Math.max(Style.cornerRadius, 12)
  color: Util.alpha(Commons.Color.menu.background, 0.94)
  borderSpec: Border.surfaceSpec("menu", "border", Commons.Color.menu.border, 1)
  clip: true
  visible: panel.opacity > 0.01

  opacity: panel.open ? 1.0 : 0.0

  Behavior on x {
    NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
  }
  Behavior on opacity {
    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
  }

  onOpenChanged: if (panel.open) pathInput.text = panel.bgImagePath

  // Click-away catcher: returns keyboard focus to the typing handler
  MouseArea {
    anchors.fill: parent
    onClicked: panel.focusReleased()
  }

  // ---------------------------------------------------- Panel header
  Item {
    id: panelHeader
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    height: 52

    OutlinedText {
      anchors.left: parent.left
      anchors.leftMargin: 24
      anchors.verticalCenter: parent.verticalCenter
      text: "Settings"
      font.family: Style.font.family
      font.pixelSize: 16
      font.bold: true
      color: panel.themeAccent
    }

    Rectangle {
      id: closeBtn
      anchors.right: parent.right
      anchors.rightMargin: 16
      anchors.verticalCenter: parent.verticalCenter
      width: 30
      height: 30
      radius: 8
      color: closeMouse.containsMouse ? Util.alpha(Commons.Color.menu.text, 0.1) : "transparent"

      OutlinedText {
        anchors.centerIn: parent
        text: "✕"
        font.family: Style.font.family
        font.pixelSize: 13
        color: Util.alpha(Commons.Color.menu.text, 0.7)
      }

      MouseArea {
        id: closeMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: panel.closeRequested()
      }
    }

    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: 1
      color: Util.alpha(Commons.Color.menu.text, 0.08)
    }
  }

  // ---------------------------------------------------- Scrollable content
  Flickable {
    id: panelFlickable
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: panelHeader.bottom
    anchors.bottom: parent.bottom
    clip: true
    contentWidth: width
    contentHeight: contentColumn.height + 24
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: contentColumn
      x: 24
      y: 16
      width: panelFlickable.width - 48
      spacing: 10

      // ================================== Section: Typing
      OutlinedText {
        text: "TYPING"
        font.family: Style.font.family
        font.pixelSize: 11
        font.bold: true
        color: Util.alpha(Commons.Color.menu.text, 0.4)
      }

      SegGroup {
        label: "Mode"
        labels: ["Quote", "Time", "Words"]
        values: ["quote", "time", "words"]
        current: panel.mode
        onChosen: function(value) { panel.settingsChanged("mode", value); panel.commit() }
      }

      SegGroup {
        label: "Quote length"
        labels: ["Short", "Medium"]
        values: ["short", "medium"]
        current: panel.quoteLength
        onChosen: function(value) { panel.settingsChanged("quoteLength", value); panel.commit() }
      }

      SegGroup {
        label: "Duration"
        labels: ["15s", "30s", "60s"]
        values: ["15", "30", "60"]
        current: String(panel.duration)
        onChosen: function(value) { panel.settingsChanged("duration", value); panel.commit() }
      }

      SegGroup {
        label: "Word count"
        labels: ["10w", "25w", "50w", "100w"]
        values: ["10", "25", "50", "100"]
        current: String(panel.wordCount)
        onChosen: function(value) { panel.settingsChanged("wordCount", value); panel.commit() }
      }

      SegGroup {
        label: "Language"
        labels: ["English", "Español"]
        values: ["english", "spanish"]
        current: panel.language
        onChosen: function(value) { panel.settingsChanged("language", value); panel.commit() }
      }

      ToggleRow {
        label: "Punctuation"
        checked: panel.punctuation
        onToggled: function(checked) { panel.settingsChanged("punctuation", checked); panel.commit() }
      }

      ToggleRow {
        label: "Numbers"
        checked: panel.numbers
        onToggled: function(checked) { panel.settingsChanged("numbers", checked); panel.commit() }
      }

      Item { width: 1; height: 10 }

      // ================================== Section: Sound
      OutlinedText {
        text: "SOUND"
        font.family: Style.font.family
        font.pixelSize: 11
        font.bold: true
        color: Util.alpha(Commons.Color.menu.text, 0.4)
      }

      SegGroup {
        label: "Theme"
        labels: ["Thock", "Cream", "Topre", "Clicky", "Typewriter", "Off"]
        values: ["thock", "cream", "topre", "clicky", "typewriter", "off"]
        current: panel.soundTheme
        onChosen: function(value) { panel.settingsChanged("soundTheme", value); panel.commit() }
      }

      SliderRow {
        label: "Volume"
        percent: true
        value: panel.soundVolume
        onChanged: function(value) { panel.settingsChanged("soundVolume", value) }
        onCommitted: panel.commit()
      }

      Item { width: 1; height: 10 }

      // ================================== Section: Background
      OutlinedText {
        text: "BACKGROUND"
        font.family: Style.font.family
        font.pixelSize: 11
        font.bold: true
        color: Util.alpha(Commons.Color.menu.text, 0.4)
      }

      ToggleRow {
        label: "Image"
        checked: panel.bgImageEnabled
        onToggled: function(checked) { panel.settingsChanged("bgImageEnabled", checked); panel.commit() }
      }

      Column {
        width: parent.width
        spacing: 6

        OutlinedText {
          text: "Image path"
          font.family: Style.font.family
          font.pixelSize: 11
          color: Util.alpha(Commons.Color.menu.text, 0.55)
        }

        Rectangle {
          width: parent.width
          height: 34
          radius: 6
          color: pathInput.activeFocus ? Util.alpha(Commons.Color.menu.text, 0.08) : Util.alpha(Commons.Color.menu.text, 0.04)
          border.color: pathInput.activeFocus ? Util.alpha(panel.themeAccent, 0.5) : Util.alpha(Commons.Color.menu.text, 0.15)
          border.width: 1

          TextInput {
            id: pathInput
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            text: panel.bgImagePath
            color: Commons.Color.menu.text
            font.family: Style.font.family
            font.pixelSize: 11
            clip: true
            cursorVisible: activeFocus
            selectionColor: Util.alpha(panel.themeAccent, 0.4)

            Text {
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              visible: pathInput.text === "" && !pathInput.activeFocus
              text: "path to image (empty = none)"
              font.family: Style.font.family
              font.pixelSize: 11
              color: Util.alpha(Commons.Color.menu.text, 0.3)
            }

            onEditingFinished: {
              panel.settingsChanged("bgImagePath", pathInput.text)
              panel.commit()
            }

            Keys.onEscapePressed: function(event) {
              pathInput.text = panel.bgImagePath
              panel.focusReleased()
              event.accepted = true
            }
          }
        }
      }

      SliderRow {
        label: "Blur"
        value: panel.bgBlur
        onChanged: function(value) { panel.settingsChanged("bgBlur", value) }
        onCommitted: panel.commit()
      }

      ToggleRow {
        label: "Dither"
        checked: panel.bgDither
        onToggled: function(checked) { panel.settingsChanged("bgDither", checked); panel.commit() }
      }

      SliderRow {
        label: "Dither intensity"
        value: panel.bgDitherIntensity
        onChanged: function(value) { panel.settingsChanged("bgDitherIntensity", value) }
        onCommitted: panel.commit()
      }

      StepperRow {
        label: "Color levels"
        min: 2
        max: 16
        value: Math.round(panel.bgColorLevels)
        onChanged: function(value) { panel.settingsChanged("bgColorLevels", value) }
        onCommitted: panel.commit()
      }

      StepperRow {
        label: "Cell size"
        min: 1
        max: 6
        value: Math.round(panel.bgCellSize)
        onChanged: function(value) { panel.settingsChanged("bgCellSize", value) }
        onCommitted: panel.commit()
      }

      SliderRow {
        label: "Dim"
        value: panel.bgDim
        onChanged: function(value) { panel.settingsChanged("bgDim", value) }
        onCommitted: panel.commit()
      }

      SliderRow {
        label: "Adaptive dim"
        value: panel.bgAdaptiveDim
        onChanged: function(value) { panel.settingsChanged("bgAdaptiveDim", value) }
        onCommitted: panel.commit()
      }

      ToggleRow {
        label: "Vignette"
        checked: panel.bgVignette
        onToggled: function(checked) { panel.settingsChanged("bgVignette", checked); panel.commit() }
      }

      ToggleRow {
        label: "Adaptive accent"
        checked: panel.bgAdaptiveAccent
        onToggled: function(checked) { panel.settingsChanged("bgAdaptiveAccent", checked); panel.commit() }
      }
    }
  }

  // ---------------------------------------------------- Inline components

  // Label + row of selectable chips bound to a string/number setting
  component SegGroup: Column {
    id: seg
    width: parent.width
    spacing: 6

    property string label: ""
    property var labels: []
    property var values: []
    property string current: ""
    signal chosen(var value)

    OutlinedText {
      text: seg.label
      font.family: Style.font.family
      font.pixelSize: 11
      color: Util.alpha(Commons.Color.menu.text, 0.55)
    }

    Row {
      spacing: 6

      Repeater {
        model: seg.labels.length

        delegate: Rectangle {
          id: segChip
          property string chipLabel: seg.labels[index]
          property var chipValue: seg.values[index]
          readonly property bool isSelected: String(seg.current) === String(chipValue)

          width: chipLabel ? chipText.contentWidth + 20 : 40
          height: 26
          radius: 6
          color: isSelected
            ? Commons.Color.menu.selectedBackground
            : (segMouse.containsMouse ? Util.alpha(Commons.Color.menu.text, 0.08) : Util.alpha(Commons.Color.menu.text, 0.04))
          border.color: isSelected ? Util.alpha(panel.themeAccent, 0.5) : Util.alpha(Commons.Color.menu.text, 0.12)
          border.width: 1

          OutlinedText {
            id: chipText
            anchors.centerIn: parent
            text: segChip.chipLabel
            font.family: Style.font.family
            font.pixelSize: 11
            font.bold: segChip.isSelected
            color: segChip.isSelected ? panel.themeAccent : Util.alpha(Commons.Color.menu.text, 0.55)
          }

          MouseArea {
            id: segMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: seg.chosen(segChip.chipValue)
          }
        }
      }
    }
  }

  // Label + pill switch on the right
  component ToggleRow: Item {
    id: toggleRow
    width: parent.width
    height: 30

    property string label: ""
    property bool checked: false
    signal toggled(bool checked)

    OutlinedText {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: toggleRow.label
      font.family: Style.font.family
      font.pixelSize: 12
      color: toggleRow.checked ? Commons.Color.menu.text : Util.alpha(Commons.Color.menu.text, 0.55)
    }

    Rectangle {
      id: pill
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      width: 34
      height: 18
      radius: 9
      color: toggleRow.checked ? Util.alpha(panel.themeAccent, 0.35) : Util.alpha(Commons.Color.menu.text, 0.1)
      border.color: toggleRow.checked ? Util.alpha(panel.themeAccent, 0.6) : Util.alpha(Commons.Color.menu.text, 0.2)
      border.width: 1

      Rectangle {
        width: 12
        height: 12
        radius: 6
        anchors.verticalCenter: parent.verticalCenter
        x: toggleRow.checked ? parent.width - width - 3 : 3
        color: toggleRow.checked ? panel.themeAccent : Util.alpha(Commons.Color.menu.text, 0.5)

        Behavior on x {
          NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: toggleRow.toggled(!toggleRow.checked)
      }
    }
  }

  // Label + current value + draggable slider track
  component SliderRow: Item {
    id: sliderRow
    width: parent.width
    height: 44

    property string label: ""
    property real value: 0
    property real from: 0
    property real to: 1
    property bool percent: false
    signal changed(real value)
    signal committed()

    readonly property real frac: Math.max(0, Math.min(1, (value - from) / (to - from)))

    OutlinedText {
      anchors.left: parent.left
      anchors.top: parent.top
      text: sliderRow.label
      font.family: Style.font.family
      font.pixelSize: 12
      color: Util.alpha(Commons.Color.menu.text, 0.55)
    }

    OutlinedText {
      anchors.right: parent.right
      anchors.top: parent.top
      text: sliderRow.percent ? Math.round(sliderRow.value * 100) + "%" : sliderRow.value.toFixed(2)
      font.family: Style.font.family
      font.pixelSize: 11
      font.bold: true
      color: panel.themeAccent
    }

    Item {
      id: trackZone
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: 18

      Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        height: 5
        radius: 2.5
        color: Util.alpha(Commons.Color.menu.text, 0.12)
      }

      Rectangle {
        anchors.verticalCenter: track.verticalCenter
        anchors.left: track.left
        height: track.height
        radius: track.radius
        color: panel.themeAccent
        width: track.width * sliderRow.frac
      }

      Rectangle {
        width: 14
        height: 14
        radius: 7
        anchors.verticalCenter: track.verticalCenter
        x: (track.width - width) * sliderRow.frac
        color: panel.themeAccent
        border.color: Commons.Color.menu.background
        border.width: 2
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        function apply(mouseX) {
          var f = Math.max(0, Math.min(1, mouseX / trackZone.width))
          sliderRow.changed(sliderRow.from + f * (sliderRow.to - sliderRow.from))
        }

        onPressed: function(mouse) { apply(mouse.x) }
        onPositionChanged: function(mouse) { if (pressed) apply(mouse.x) }
        onReleased: sliderRow.committed()
        onCanceled: sliderRow.committed()
      }
    }
  }

  // Label + [−] value [+] stepper for integer settings
  component StepperRow: Item {
    id: stepRow
    width: parent.width
    height: 30

    property string label: ""
    property int value: 2
    property int min: 2
    property int max: 16
    signal changed(int value)
    signal committed()

    function stepBy(delta) {
      var next = Math.max(min, Math.min(max, value + delta))
      if (next === value) return
      changed(next)
      committed()
    }

    OutlinedText {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: stepRow.label
      font.family: Style.font.family
      font.pixelSize: 12
      color: Util.alpha(Commons.Color.menu.text, 0.55)
    }

    Row {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: 6

      Rectangle {
        width: 26
        height: 26
        radius: 6
        opacity: stepRow.value > stepRow.min ? 1.0 : 0.3
        color: minusMouse.containsMouse ? Util.alpha(Commons.Color.menu.text, 0.1) : Util.alpha(Commons.Color.menu.text, 0.05)
        border.color: Util.alpha(Commons.Color.menu.text, 0.15)
        border.width: 1

        OutlinedText {
          anchors.centerIn: parent
          text: "−"
          font.family: Style.font.family
          font.pixelSize: 14
          color: Commons.Color.menu.text
        }

        MouseArea {
          id: minusMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: stepRow.stepBy(-1)
        }
      }

      Rectangle {
        width: 44
        height: 26
        radius: 6
        color: Util.alpha(Commons.Color.menu.text, 0.04)
        border.color: Util.alpha(Commons.Color.menu.text, 0.12)
        border.width: 1

        OutlinedText {
          anchors.centerIn: parent
          text: String(stepRow.value)
          font.family: Style.font.family
          font.pixelSize: 12
          font.bold: true
          color: panel.themeAccent
        }
      }

      Rectangle {
        width: 26
        height: 26
        radius: 6
        opacity: stepRow.value < stepRow.max ? 1.0 : 0.3
        color: plusMouse.containsMouse ? Util.alpha(Commons.Color.menu.text, 0.1) : Util.alpha(Commons.Color.menu.text, 0.05)
        border.color: Util.alpha(Commons.Color.menu.text, 0.15)
        border.width: 1

        OutlinedText {
          anchors.centerIn: parent
          text: "+"
          font.family: Style.font.family
          font.pixelSize: 14
          color: Commons.Color.menu.text
        }

        MouseArea {
          id: plusMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: stepRow.stepBy(1)
        }
      }
    }
  }
}
