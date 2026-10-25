import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "core/Words.js" as WordsModule
import "core/Quotes.js" as QuotesModule
import "core/Engine.js" as EngineModule
import "core/History.js" as HistoryModule
import "core/Settings.js" as SettingsModule

Item {
  id: root

  property bool opened: false
  property string activeView: "test" // "test" | "stats"
  property string mode: "quote" // "quote" | "time"
  property string quoteLength: "short" // "short" | "medium"
  property int duration: 15 // 15 or 30 seconds
  property var session: null
  property var stats: ({ wpm: 0, rawWpm: 0, accuracy: 100, timeLeft: 15, elapsedSeconds: 0, isFinished: false, status: "idle", quote: null, totalKeypresses: 0 })
  property int sessionRevision: 0

  property string soundTheme: "thock" // "thock" | "clicky" | "typewriter" | "off"
  property double soundVolume: 0.55
  property bool settingsLoaded: false
  property string soundBaseDir: Quickshell.env("HOME") + "/Projects/oma-type/assets/sounds"
  property double lastSoundTime: 0

  property var history: []
  property var summary: ({ totalTests: 0, bestWpm: 0, avgWpm: 0, avgAccuracy: 0, totalSeconds: 0 })
  property bool recordedCurrent: false

  function open() {
    root.opened = true
    root.activeView = "test"
    root.resetTest()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() {
    root.opened = false
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function setMode(m) {
    if (root.mode === m) return
    root.mode = m
    root.resetTest()
    root.saveSettings()
  }

  function setDuration(d) {
    root.duration = d
    root.resetTest()
    root.saveSettings()
  }

  function setQuoteLength(len) {
    root.quoteLength = len
    root.resetTest()
    root.saveSettings()
  }

  function toggleQuoteLength() {
    root.quoteLength = (root.quoteLength === "short") ? "medium" : "short"
    root.resetTest()
    root.saveSettings()
  }

  function toggleDuration() {
    root.duration = (root.duration === 15) ? 30 : 15
    root.resetTest()
    root.saveSettings()
  }

  function toggleMode() {
    root.activeView = "test"
    root.setMode(root.mode === "quote" ? "time" : "quote")
  }

  function toggleLengthOrDuration() {
    root.activeView = "test"
    if (root.mode === "quote") {
      root.toggleQuoteLength()
    } else {
      root.toggleDuration()
    }
  }

  function toggleStatsView() {
    root.activeView = (root.activeView === "stats") ? "test" : "stats"
    if (root.activeView === "stats") {
      root.summary = HistoryModule.getSummary(root.history)
      graphAnim.restart()
    }
  }

  function cycleSoundTheme() {
    var themes = ["thock", "clicky", "typewriter", "off"]
    var nextIdx = (themes.indexOf(root.soundTheme) + 1) % themes.length
    root.soundTheme = themes[nextIdx]
    root.playKeySound()
    root.saveSettings()
  }

  function loadSettings(jsonText) {
    var s = SettingsModule.parseSettings(jsonText)
    root.soundTheme = s.soundTheme
    root.mode = s.mode
    root.quoteLength = s.quoteLength
    root.duration = s.duration
    root.soundVolume = s.soundVolume
    root.settingsLoaded = true
    root.resetTest()
    if (!jsonText || jsonText === "{}" || jsonText.trim() === "") {
      root.saveSettings()
    }
  }

  function saveSettings() {
    if (!root.settingsLoaded) return
    var data = {
      soundTheme: root.soundTheme,
      mode: root.mode,
      quoteLength: root.quoteLength,
      duration: root.duration,
      soundVolume: root.soundVolume
    }
    settingsFile.setText(SettingsModule.serializeSettings(data))
  }

  function playKeySound() {
    if (root.soundTheme === "off") return
    var now = Date.now()
    if (now - root.lastSoundTime < 35) return
    root.lastSoundTime = now

    var file = ""
    if (root.soundTheme === "thock") {
      file = root.soundBaseDir + "/thock/" + (Math.floor(Math.random() * 4) + 1) + ".wav"
    } else if (root.soundTheme === "clicky") {
      file = root.soundBaseDir + "/clicky/" + (Math.floor(Math.random() * 3) + 1) + ".wav"
    } else if (root.soundTheme === "typewriter") {
      file = root.soundBaseDir + "/typewriter/" + (Math.floor(Math.random() * 3) + 1) + ".wav"
    }

    if (file) {
      Quickshell.execDetached(["pw-play", "--volume", "" + root.soundVolume, file])
    }
  }

  function resetTest() {
    root.recordedCurrent = false
    root.sessionRevision = 0
    if (wordsFlickable) wordsFlickable.contentY = 0

    if (root.mode === "time") {
      var wordList = WordsModule.getRandomWords(80)
      root.session = EngineModule.createSession({ mode: "time", duration: root.duration, words: wordList })
    } else {
      var lastQuoteId = root.session && root.session.quote ? root.session.quote.id : null
      var q = QuotesModule.getRandomQuote(root.quoteLength, lastQuoteId)
      var words = QuotesModule.splitQuoteIntoWords(q.text)
      root.session = EngineModule.createSession({ mode: "quote", words: words, quote: q })
    }
    root.updateStats()
    wordsRepeater.model = 0
    wordsRepeater.model = root.session.words.length
    Qt.callLater(root.updateCaretPosition)
  }

  function updateStats() {
    if (!root.session) return
    root.stats = EngineModule.calculateStats(root.session, Date.now())

    if (root.stats.isFinished && !root.recordedCurrent) {
      root.recordFinishedTest()
    }
  }

  function updateCaretPosition() {
    if (!root.session || root.stats.isFinished) return
    var wItem = wordsRepeater.itemAt(root.session.wordIndex)
    if (!wItem) return

    var charX = 0
    if (root.session.charIndex < wItem.charCount) {
      var cItem = wItem.getCharItem(root.session.charIndex)
      if (cItem) charX = cItem.x
    } else {
      var sItem = wItem.getSpaceItem()
      if (sItem) charX = sItem.x
    }

    smoothCaret.targetX = wItem.x + charX
    smoothCaret.targetY = wItem.y + 2

    // Auto-scroll if word is below current viewport
    var caretBottom = wItem.y + 44
    if (caretBottom > wordsFlickable.contentY + wordsFlickable.height) {
      wordsFlickable.contentY = Math.max(0, wItem.y - 12)
    } else if (wItem.y < wordsFlickable.contentY) {
      wordsFlickable.contentY = Math.max(0, wItem.y - 12)
    }
  }

  function recordFinishedTest() {
    root.recordedCurrent = true
    var entry = HistoryModule.createEntry(root.stats, root.mode)
    root.history = HistoryModule.addEntry(root.history, entry, 200)
    root.summary = HistoryModule.getSummary(root.history)
    historyFile.setText(JSON.stringify(root.history, null, 2))
  }

  function loadHistory(jsonText) {
    try {
      var data = JSON.parse(jsonText || "[]")
      if (Array.isArray(data)) {
        root.history = data
        root.summary = HistoryModule.getSummary(data)
      }
    } catch (e) {
      root.history = []
      root.summary = HistoryModule.getSummary([])
    }
  }

  FileView {
    id: settingsFile
    path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/oma-type/settings.json"
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadSettings(text())
    onLoadFailed: function(err) { root.loadSettings("{}") }
  }

  FileView {
    id: historyFile
    path: Quickshell.env("HOME") + "/.local/share/oma-type/history.json"
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadHistory(text())
    onLoadFailed: function(err) { root.loadHistory("[]") }
  }

  Timer {
    id: tickTimer
    interval: 100
    repeat: true
    running: root.opened && root.session && root.session.status === "running"
    onTriggered: {
      EngineModule.tick(root.session, Date.now())
      root.updateStats()
    }
  }

  IpcHandler {
    target: "oma-type"

    function toggle(): string {
      root.toggle()
      return root.opened ? "shown" : "hidden"
    }

    function show(): string {
      root.open()
      return "shown"
    }

    function hide(): string {
      root.close()
      return "hidden"
    }

    function isOpen(): string {
      return root.opened ? "true" : "false"
    }

    function reset(): string {
      root.resetTest()
      return "ok"
    }

    function ping(): string {
      return "ok"
    }
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "oma-type"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    onVisibleChanged: {
      if (visible) Qt.callLater(function() { keyCatcher.forceActiveFocus() })
    }

    // Scrim backdrop with smooth fade-in
    Rectangle {
      anchors.fill: parent
      color: "#000000"
      opacity: root.opened ? 0.72 : 0.0

      Behavior on opacity {
        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
      }

      MouseArea {
        anchors.fill: parent
        onClicked: root.close()
      }
    }

    // Centered card (Scaled 1.25x: 1080×640)
    BorderSurface {
      id: card
      width: Math.min(1080, parent.width - Style.space(32))
      height: Math.min(640, parent.height - Style.space(32))
      anchors.centerIn: parent
      radius: Math.max(Style.cornerRadius, 14)
      color: Commons.Color.menu.background
      borderSpec: Border.surfaceSpec("menu", "border", Commons.Color.menu.border, 1)
      clip: true

      opacity: root.opened ? 1.0 : 0.0
      scale: root.opened ? 1.0 : 0.96

      Behavior on opacity {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
      }
      Behavior on scale {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
      }

      MouseArea {
        anchors.fill: parent
        onClicked: keyCatcher.forceActiveFocus()
      }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true
        Keys.priority: Keys.BeforeItem

        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            if (root.activeView === "stats") {
              root.activeView = "test"
              event.accepted = true
              return
            }
            root.close()
            event.accepted = true
            return
          }

          if (event.key === Qt.Key_Tab) {
            root.activeView = "test"
            root.resetTest()
            event.accepted = true
            return
          }

          // Shortcuts: F-keys and Ctrl combinations
          var isCtrl = (event.modifiers & Qt.ControlModifier)

          // F1 or Ctrl+M: Toggle Mode (Quote <-> Time)
          if (event.key === Qt.Key_F1 || (isCtrl && event.key === Qt.Key_M)) {
            root.toggleMode()
            event.accepted = true
            return
          }

          // F2 or Ctrl+L / Ctrl+D: Toggle Length (short/medium) or Duration (15s/30s)
          if (event.key === Qt.Key_F2 || (isCtrl && (event.key === Qt.Key_L || event.key === Qt.Key_D))) {
            root.toggleLengthOrDuration()
            event.accepted = true
            return
          }

          // F3 or Ctrl+S: Cycle Sound Theme (thock -> clicky -> typewriter -> off)
          if (event.key === Qt.Key_F3 || (isCtrl && event.key === Qt.Key_S)) {
            root.cycleSoundTheme()
            event.accepted = true
            return
          }

          // F4 or Ctrl+H / Ctrl+E: Toggle Stats view
          if (event.key === Qt.Key_F4 || (isCtrl && (event.key === Qt.Key_H || event.key === Qt.Key_E))) {
            root.toggleStatsView()
            event.accepted = true
            return
          }

          if (root.activeView === "stats") {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
              root.activeView = "test"
              root.resetTest()
              event.accepted = true
              return
            }
            return
          }

          if (root.stats.isFinished) {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              root.resetTest()
              event.accepted = true
              return
            }
            return
          }

          // Ignore any other Ctrl combination so it doesn't feed stray control chars
          if (isCtrl) return

          var keyStr = ""
          if (event.key === Qt.Key_Backspace) keyStr = "Backspace"
          else if (event.key === Qt.Key_Space) keyStr = " "
          else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32) keyStr = event.text

          if (keyStr) {
            root.playKeySound()
            EngineModule.handleKey(root.session, keyStr, Date.now())
            root.sessionRevision++
            root.updateStats()
            root.updateCaretPosition()
            event.accepted = true
          }
        }
      }

      // ---------------------------------------------------- Header (Scaled 1.25x)
      Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 64
        anchors.leftMargin: 24
        anchors.rightMargin: 24

        // Top-Left: Back button
        Rectangle {
          id: backBtn
          width: 36
          height: 36
          radius: 8
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          color: backMouse.containsMouse ? Util.alpha(Commons.Color.menu.text, 0.1) : "transparent"

          Text {
            anchors.centerIn: parent
            text: "←"
            font.pixelSize: 18
            color: Util.alpha(Commons.Color.menu.text, 0.7)
          }

          MouseArea {
            id: backMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (root.activeView === "stats") root.activeView = "test"
              else root.close()
            }
          }
        }

        // Top-Center: Segmented Control Pill
        Rectangle {
          id: navPill
          height: 36
          width: pillRow.width + 16
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          radius: 9
          color: Util.alpha(Commons.Color.menu.text, 0.05)
          border.color: Util.alpha(Commons.Color.menu.text, 0.1)
          border.width: 1

          Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: 6

            // Quote Pill
            Rectangle {
              height: 28
              width: quoteContentRow.width + 18
              radius: 7
              color: (root.activeView === "test" && root.mode === "quote")
                ? Commons.Color.menu.selectedBackground
                : "transparent"

              Row {
                id: quoteContentRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: "Quote"
                  font.family: Style.font.family
                  font.pixelSize: 13
                  font.bold: root.mode === "quote"
                  color: (root.activeView === "test" && root.mode === "quote")
                    ? Commons.Color.menu.selectedText
                    : Util.alpha(Commons.Color.menu.text, 0.5)
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  visible: root.activeView === "test" && root.mode === "quote"
                  text: root.quoteLength + " ▾"
                  font.family: Style.font.family
                  font.pixelSize: 11
                  color: Util.alpha(Commons.Color.menu.selectedText, 0.75)
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (root.activeView === "test" && root.mode === "quote") {
                    root.toggleQuoteLength()
                  } else {
                    root.activeView = "test"
                    root.setMode("quote")
                  }
                }
              }
            }

            // Separator
            Rectangle {
              width: 1
              height: 16
              anchors.verticalCenter: parent.verticalCenter
              color: Util.alpha(Commons.Color.menu.text, 0.12)
            }

            // Time Pill
            Rectangle {
              height: 28
              width: timeContentRow.width + 18
              radius: 7
              color: (root.activeView === "test" && root.mode === "time")
                ? Commons.Color.menu.selectedBackground
                : "transparent"

              Row {
                id: timeContentRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: "Time"
                  font.family: Style.font.family
                  font.pixelSize: 13
                  font.bold: root.mode === "time"
                  color: (root.activeView === "test" && root.mode === "time")
                    ? Commons.Color.menu.selectedText
                    : Util.alpha(Commons.Color.menu.text, 0.5)
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  visible: root.activeView === "test" && root.mode === "time"
                  text: root.duration + "s ▾"
                  font.family: Style.font.family
                  font.pixelSize: 11
                  color: Util.alpha(Commons.Color.menu.selectedText, 0.75)
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (root.activeView === "test" && root.mode === "time") {
                    root.toggleDuration()
                  } else {
                    root.activeView = "test"
                    root.setMode("time")
                  }
                }
              }
            }

            // Separator
            Rectangle {
              width: 1
              height: 16
              anchors.verticalCenter: parent.verticalCenter
              color: Util.alpha(Commons.Color.menu.text, 0.12)
            }

            // Stats Pill
            Rectangle {
              height: 28
              width: statsContentText.contentWidth + 18
              radius: 7
              color: root.activeView === "stats"
                ? Commons.Color.menu.selectedBackground
                : "transparent"

              Text {
                id: statsContentText
                anchors.centerIn: parent
                text: "Stats"
                font.family: Style.font.family
                font.pixelSize: 13
                font.bold: root.activeView === "stats"
                color: root.activeView === "stats"
                  ? Commons.Color.menu.selectedText
                  : Util.alpha(Commons.Color.menu.text, 0.5)
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.activeView = (root.activeView === "stats") ? "test" : "stats"
                  if (root.activeView === "stats") {
                    root.summary = HistoryModule.getSummary(root.history)
                    graphAnim.restart()
                  }
                }
              }
            }
          }
        }

        // Top-Right: Sound switch & Live metrics
        Row {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: 16

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.soundTheme === "off" ? "sound: off" : root.soundTheme
            font.family: Style.font.family
            font.pixelSize: 13
            color: root.soundTheme !== "off" ? Util.alpha(Commons.Color.menu.text, 0.5) : Util.alpha(Commons.Color.menu.text, 0.25)
            Behavior on color { ColorAnimation { duration: 100 } }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.cycleSoundTheme()
            }
          }

          // Live Timer / Stopwatch (Test View)
          Text {
            visible: root.activeView === "test"
            anchors.verticalCenter: parent.verticalCenter
            text: root.mode === "time"
              ? root.stats.timeLeft + "s"
              : (root.stats.status === "idle" ? "0.0s" : root.stats.elapsedSeconds + "s")
            font.family: Style.font.family
            font.pixelSize: 18
            font.bold: true
            color: (root.mode === "time" && root.stats.timeLeft <= 3) ? "#e06c75" : Commons.Color.menu.selectedText
          }

          Text {
            visible: root.activeView === "test"
            anchors.verticalCenter: parent.verticalCenter
            text: root.stats.wpm + " wpm"
            font.family: Style.font.family
            font.pixelSize: 13
            color: Util.alpha(Commons.Color.menu.text, 0.4)
          }

          Text {
            visible: root.activeView === "test"
            anchors.verticalCenter: parent.verticalCenter
            text: root.stats.accuracy + "%"
            font.family: Style.font.family
            font.pixelSize: 13
            color: Util.alpha(Commons.Color.menu.text, 0.4)
          }
        }
      }

      // Hairline separator
      Rectangle {
        id: sep
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        height: 1
        color: Util.alpha(Commons.Color.menu.text, 0.08)
      }

      // ---------------------------------------------------- Main Body (Centered Content)
      Item {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sep.bottom
        anchors.bottom: footer.top
        anchors.margins: 32
        anchors.bottomMargin: 12
        clip: true

        // =================================== VIEW 1: TYPING TEST
        Item {
          id: testViewContainer
          anchors.fill: parent
          opacity: root.activeView === "test" ? 1.0 : 0.0
          visible: opacity > 0.01

          Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
          }

          // Active Typing: Vertically and Horizontally Centered (Scaled 1.25x)
          Item {
            anchors.fill: parent
            visible: !root.stats.isFinished

            Item {
              id: centeredTypingBox
              anchors.centerIn: parent
              width: Math.min(960, parent.width)
              height: 310

              Flickable {
                id: wordsFlickable
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: quoteAuthorRow.top
                anchors.bottomMargin: 20
                clip: true
                contentWidth: width
                contentHeight: flowWrapper.height
                interactive: false

                Item {
                  id: flowWrapper
                  width: wordsFlickable.width
                  height: flowContainer.height

                  // Signature Raycast / Monkeytype Smooth Caret (Scaled 1.25x)
                  Rectangle {
                    id: smoothCaret
                    width: 3.2
                    height: 35
                    color: Commons.Color.menu.selectedText
                    visible: !root.stats.isFinished && root.session && root.session.status !== "finished"
                    z: 10

                    property real targetX: 0
                    property real targetY: 0

                    x: targetX
                    y: targetY

                    Behavior on x {
                      enabled: root.session && root.session.status === "running"
                      NumberAnimation { duration: 65; easing.type: Easing.OutQuad }
                    }
                    Behavior on y {
                      NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
                    }

                    SequentialAnimation on opacity {
                      running: !root.stats.isFinished
                      loops: Animation.Infinite
                      NumberAnimation { to: 1; duration: 0 }
                      PauseAnimation { duration: 450 }
                      NumberAnimation { to: 0; duration: 0 }
                      PauseAnimation { duration: 450 }
                    }
                  }

                  Flow {
                    id: flowContainer
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 16

                    Repeater {
                      id: wordsRepeater
                      model: root.session ? root.session.words.length : 0

                      delegate: Row {
                        id: wordRow
                        readonly property int wIndex: index
                        readonly property var wData: root.session ? root.session.words[wIndex] : null
                        readonly property bool isCurrent: root.session && root.session.wordIndex === wIndex
                        readonly property int charCount: wData ? wData.chars.length : 0

                        function getCharItem(idx) { return charRepeater.itemAt(idx) }
                        function getSpaceItem() { return spaceBox }

                        spacing: 0

                        Repeater {
                          id: charRepeater
                          model: wData ? wData.chars.length : 0

                          delegate: Item {
                            id: charBox
                            width: charText.contentWidth
                            height: charText.contentHeight

                            readonly property var cData: wData ? wData.chars[index] : null

                            Text {
                              id: charText
                              text: charBox.cData ? charBox.cData.char : ""
                              font.family: Style.font.family
                              font.pixelSize: 30
                              color: {
                                root.sessionRevision
                                if (!charBox.cData) return Util.alpha(Commons.Color.menu.text, 0.35)
                                if (charBox.cData.state === "correct") return Commons.Color.menu.text
                                if (charBox.cData.state === "incorrect") return "#e06c75"
                                return Util.alpha(Commons.Color.menu.text, 0.35)
                              }
                            }
                          }
                        }

                        // Extra mistyped characters
                        Repeater {
                          model: {
                            root.sessionRevision
                            return (wData && wData.extra) ? wData.extra.length : 0
                          }

                          delegate: Text {
                            text: {
                              root.sessionRevision
                              return (wData && wData.extra) ? wData.extra[index] : ""
                            }
                            font.family: Style.font.family
                            font.pixelSize: 30
                            font.bold: true
                            color: "#e06c75"
                          }
                        }

                        // Trailing space
                        Item {
                          id: spaceBox
                          width: spaceText.contentWidth
                          height: spaceText.contentHeight

                          Text {
                            id: spaceText
                            text: " "
                            font.family: Style.font.family
                            font.pixelSize: 30
                          }
                        }
                      }
                    }
                  }
                }
              }

              // Author attribution in quote mode
              Row {
                id: quoteAuthorRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 26
                visible: root.mode === "quote" && root.session && root.session.quote

                Text {
                  text: root.session && root.session.quote ? "— " + root.session.quote.source : ""
                  font.family: Style.font.family
                  font.pixelSize: 14
                  font.italic: true
                  color: Util.alpha(Commons.Color.menu.text, 0.35)
                }
              }
            }
          }

          // Test Finished Summary: MASSIVE 115px WPM
          Column {
            anchors.centerIn: parent
            spacing: 16
            visible: root.stats.isFinished

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.stats.wpm
              font.family: Style.font.family
              font.pixelSize: 115
              font.bold: true
              color: Commons.Color.menu.selectedText
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "WORDS PER MINUTE"
              font.family: Style.font.family
              font.pixelSize: 13
              font.bold: true
              color: Util.alpha(Commons.Color.menu.text, 0.4)
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              visible: root.mode === "quote" && root.stats.quote
              text: root.stats.quote ? "— " + root.stats.quote.source : ""
              font.family: Style.font.family
              font.pixelSize: 16
              font.italic: true
              color: Util.alpha(Commons.Color.menu.text, 0.6)
            }

            Row {
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: 32
              anchors.topMargin: 12

              Text {
                text: root.stats.accuracy + "% accuracy"
                font.family: Style.font.family
                font.pixelSize: 18
                color: Commons.Color.menu.text
              }

              Text {
                text: "·"
                color: Util.alpha(Commons.Color.menu.text, 0.3)
              }

              Text {
                text: root.stats.elapsedSeconds + "s time"
                font.family: Style.font.family
                font.pixelSize: 18
                color: Commons.Color.menu.text
              }

              Text {
                text: "·"
                color: Util.alpha(Commons.Color.menu.text, 0.3)
              }

              Text {
                text: root.stats.rawWpm + " raw"
                font.family: Style.font.family
                font.pixelSize: 18
                color: Commons.Color.menu.text
              }
            }

            Item { width: 1; height: 12 }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "tab or enter to restart"
              font.family: Style.font.family
              font.pixelSize: 13
              color: Util.alpha(Commons.Color.menu.text, 0.35)
            }
          }
        }

        // =================================== VIEW 2: STATS & GRAPH (Scaled 1.25x)
        Item {
          id: statsViewContainer
          anchors.fill: parent
          opacity: root.activeView === "stats" ? 1.0 : 0.0
          visible: opacity > 0.01

          Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
          }

          Column {
            anchors.fill: parent
            spacing: 20

            // 1. Pure Typography Metrics (34px)
            Row {
              width: parent.width

              Column {
                width: parent.width / 4
                spacing: 3
                Text {
                  text: root.summary.bestWpm > 0 ? String(root.summary.bestWpm) : "—"
                  font.family: Style.font.family
                  font.pixelSize: 34
                  font.bold: true
                  color: Commons.Color.menu.selectedText
                }
                Text {
                  text: "best wpm"
                  font.family: Style.font.family
                  font.pixelSize: 12
                  color: Util.alpha(Commons.Color.menu.text, 0.4)
                }
              }

              Column {
                width: parent.width / 4
                spacing: 3
                Text {
                  text: root.summary.avgWpm > 0 ? String(root.summary.avgWpm) : "—"
                  font.family: Style.font.family
                  font.pixelSize: 34
                  font.bold: true
                  color: Commons.Color.menu.text
                }
                Text {
                  text: "avg wpm"
                  font.family: Style.font.family
                  font.pixelSize: 12
                  color: Util.alpha(Commons.Color.menu.text, 0.4)
                }
              }

              Column {
                width: parent.width / 4
                spacing: 3
                Text {
                  text: root.summary.avgAccuracy > 0 ? root.summary.avgAccuracy + "%" : "—"
                  font.family: Style.font.family
                  font.pixelSize: 34
                  font.bold: true
                  color: Commons.Color.menu.text
                }
                Text {
                  text: "accuracy"
                  font.family: Style.font.family
                  font.pixelSize: 12
                  color: Util.alpha(Commons.Color.menu.text, 0.4)
                }
              }

              Column {
                width: parent.width / 4
                spacing: 3
                Text {
                  text: String(root.summary.totalTests)
                  font.family: Style.font.family
                  font.pixelSize: 34
                  font.bold: true
                  color: Commons.Color.menu.text
                }
                Text {
                  text: "tests completed"
                  font.family: Style.font.family
                  font.pixelSize: 12
                  color: Util.alpha(Commons.Color.menu.text, 0.4)
                }
              }
            }

            // 2. Wireframe Chart (Height 175px)
            Item {
              width: parent.width
              height: 175

              Text {
                anchors.centerIn: parent
                visible: root.history.length < 2
                text: root.history.length === 0 ? "no test data yet" : "complete 1 more test to draw curve"
                font.family: Style.font.family
                font.pixelSize: 13
                color: Util.alpha(Commons.Color.menu.text, 0.3)
              }

              NumberAnimation {
                id: graphAnim
                target: trendCanvas
                property: "drawProgress"
                from: 0.0
                to: 1.0
                duration: 360
                easing.type: Easing.OutCubic
              }

              Canvas {
                id: trendCanvas
                anchors.fill: parent
                visible: root.history.length >= 2
                property real drawProgress: 1.0

                onDrawProgressChanged: requestPaint()

                onPaint: {
                  var ctx = getContext("2d")
                  ctx.reset()

                  var points = HistoryModule.getRecentTrend(root.history, 15)
                  if (!points || points.length < 2) return

                  var totalPts = points.length
                  var visibleCount = Math.max(2, Math.min(totalPts, Math.ceil(totalPts * drawProgress)))

                  var w = width
                  var h = height - 24
                  var maxWpm = 10
                  var minWpm = 999
                  for (var i = 0; i < totalPts; i++) {
                    if (points[i].wpm > maxWpm) maxWpm = points[i].wpm
                    if (points[i].wpm < minWpm) minWpm = points[i].wpm
                  }
                  maxWpm = Math.max(maxWpm + 5, 40)
                  minWpm = Math.max(0, minWpm - 5)

                  var range = Math.max(1, maxWpm - minWpm)
                  var stepX = (w - 24) / (totalPts - 1)

                  function getY(val) {
                    var pct = (val - minWpm) / range
                    return h - (pct * h) + 12
                  }

                  // 1. Subtle horizontal average line
                  var avgY = getY(root.summary.avgWpm)
                  ctx.strokeStyle = "rgba(255, 255, 255, 0.1)"
                  ctx.lineWidth = 1
                  ctx.setLineDash([3, 4])
                  ctx.beginPath()
                  ctx.moveTo(12, avgY)
                  ctx.lineTo(w - 12, avgY)
                  ctx.stroke()
                  ctx.setLineDash([])

                  ctx.fillStyle = "rgba(255, 255, 255, 0.25)"
                  ctx.font = "11px monospace"
                  ctx.fillText("avg " + root.summary.avgWpm, 12, avgY - 5)

                  // 2. Animated curve line
                  ctx.strokeStyle = "#56b6c2"
                  ctx.lineWidth = 2.2
                  ctx.beginPath()
                  for (var j = 0; j < visibleCount; j++) {
                    var jx = 12 + j * stepX
                    var jy = getY(points[j].wpm)
                    if (j === 0) ctx.moveTo(jx, jy)
                    else {
                      var pX = 12 + (j - 1) * stepX
                      var pY = getY(points[j - 1].wpm)
                      var mX = (pX + jx) / 2
                      ctx.bezierCurveTo(mX, pY, mX, jy, jx, jy)
                    }
                  }
                  ctx.stroke()

                  // 3. Node dots & WPM label
                  for (var k = 0; k < visibleCount; k++) {
                    var kx = 12 + k * stepX
                    var ky = getY(points[k].wpm)

                    ctx.fillStyle = "#56b6c2"
                    ctx.beginPath()
                    ctx.arc(kx, ky, 3, 0, 2 * Math.PI)
                    ctx.fill()

                    ctx.fillStyle = "rgba(255, 255, 255, 0.55)"
                    ctx.font = "10px monospace"
                    ctx.textAlign = "center"
                    ctx.fillText(points[k].wpm, kx, ky - 8)
                  }
                }
              }
            }

            // 3. Minimalist Clean Table of Recent Runs
            Column {
              width: parent.width
              spacing: 8

              Text {
                text: "recent"
                font.family: Style.font.family
                font.pixelSize: 11
                color: Util.alpha(Commons.Color.menu.text, 0.35)
              }

              Repeater {
                model: Math.min(3, root.history.length)

                delegate: Item {
                  width: statsViewContainer.width
                  height: 26

                  readonly property var hItem: root.history[index]

                  Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 20

                    Text {
                      text: hItem.mode || "time"
                      font.family: Style.font.family
                      font.pixelSize: 13
                      color: Util.alpha(Commons.Color.menu.text, 0.4)
                      width: 46
                    }

                    Text {
                      text: hItem.wpm + " wpm"
                      font.family: Style.font.family
                      font.pixelSize: 13
                      font.bold: true
                      color: Commons.Color.menu.text
                      width: 64
                    }

                    Text {
                      text: hItem.accuracy + "%"
                      font.family: Style.font.family
                      font.pixelSize: 13
                      color: Util.alpha(Commons.Color.menu.text, 0.5)
                      width: 44
                    }

                    Text {
                      visible: hItem.quoteSource && hItem.quoteSource.length > 0
                      text: hItem.quoteSource
                      font.family: Style.font.family
                      font.pixelSize: 13
                      font.italic: true
                      color: Util.alpha(Commons.Color.menu.text, 0.3)
                      elide: Text.ElideRight
                      width: 420
                    }
                  }

                  Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: hItem.elapsedSeconds + "s"
                    font.family: Style.font.family
                    font.pixelSize: 13
                    color: Util.alpha(Commons.Color.menu.text, 0.3)
                  }
                }
              }
            }
          }
        }
      }

      // ---------------------------------------------------- Footer (Scaled 1.25x)
      Rectangle {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 48
        color: Util.alpha(Commons.Color.menu.text, 0.02)

        Rectangle {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          height: 1
          color: Util.alpha(Commons.Color.menu.text, 0.06)
        }

        // Left: Omarchy glyph + Branding
        Row {
          anchors.left: parent.left
          anchors.leftMargin: 24
          anchors.verticalCenter: parent.verticalCenter
          spacing: 10

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: ""
            font.family: "omarchy"
            font.pixelSize: 16
            color: Commons.Color.menu.selectedText
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Typing Practice"
            font.family: Style.font.family
            font.pixelSize: 14
            color: Util.alpha(Commons.Color.menu.text, 0.6)
          }
        }

        // Right: Key badges
        Row {
          anchors.right: parent.right
          anchors.rightMargin: 24
          anchors.verticalCenter: parent.verticalCenter
          spacing: 14

          // Mode Hint
          Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "Mode"
              font.family: Style.font.family
              font.pixelSize: 12
              color: Util.alpha(Commons.Color.menu.text, 0.5)
            }

            Rectangle {
              width: 30
              height: 22
              radius: 5
              color: Util.alpha(Commons.Color.menu.text, 0.08)
              border.color: Util.alpha(Commons.Color.menu.text, 0.15)
              border.width: 1

              Text {
                anchors.centerIn: parent
                text: "F1"
                font.family: Style.font.family
                font.pixelSize: 11
                font.bold: true
                color: Commons.Color.menu.text
              }
            }
          }

          Rectangle {
            width: 1
            height: 14
            anchors.verticalCenter: parent.verticalCenter
            color: Util.alpha(Commons.Color.menu.text, 0.12)
          }

          // Sound Hint
          Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "Sound"
              font.family: Style.font.family
              font.pixelSize: 12
              color: Util.alpha(Commons.Color.menu.text, 0.5)
            }

            Rectangle {
              width: 30
              height: 22
              radius: 5
              color: Util.alpha(Commons.Color.menu.text, 0.08)
              border.color: Util.alpha(Commons.Color.menu.text, 0.15)
              border.width: 1

              Text {
                anchors.centerIn: parent
                text: "F3"
                font.family: Style.font.family
                font.pixelSize: 11
                font.bold: true
                color: Commons.Color.menu.text
              }
            }
          }

          Rectangle {
            width: 1
            height: 14
            anchors.verticalCenter: parent.verticalCenter
            color: Util.alpha(Commons.Color.menu.text, 0.12)
          }

          // Stats Hint
          Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "Stats"
              font.family: Style.font.family
              font.pixelSize: 12
              color: Util.alpha(Commons.Color.menu.text, 0.5)
            }

            Rectangle {
              width: 30
              height: 22
              radius: 5
              color: Util.alpha(Commons.Color.menu.text, 0.08)
              border.color: Util.alpha(Commons.Color.menu.text, 0.15)
              border.width: 1

              Text {
                anchors.centerIn: parent
                text: "F4"
                font.family: Style.font.family
                font.pixelSize: 11
                font.bold: true
                color: Commons.Color.menu.text
              }
            }
          }

          Rectangle {
            width: 1
            height: 14
            anchors.verticalCenter: parent.verticalCenter
            color: Util.alpha(Commons.Color.menu.text, 0.12)
          }

          // Restart Hint
          Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "Restart"
              font.family: Style.font.family
              font.pixelSize: 12
              color: Util.alpha(Commons.Color.menu.text, 0.5)
            }

            Rectangle {
              width: 36
              height: 22
              radius: 5
              color: Util.alpha(Commons.Color.menu.text, 0.08)
              border.color: Util.alpha(Commons.Color.menu.text, 0.15)
              border.width: 1

              Text {
                anchors.centerIn: parent
                text: "Tab"
                font.family: Style.font.family
                font.pixelSize: 11
                font.bold: true
                color: Commons.Color.menu.text
              }
            }
          }

          Rectangle {
            width: 1
            height: 14
            anchors.verticalCenter: parent.verticalCenter
            color: Util.alpha(Commons.Color.menu.text, 0.12)
          }

          // Close Hint
          Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "Close"
              font.family: Style.font.family
              font.pixelSize: 12
              color: Util.alpha(Commons.Color.menu.text, 0.5)
            }

            Rectangle {
              width: 36
              height: 22
              radius: 5
              color: Util.alpha(Commons.Color.menu.text, 0.08)
              border.color: Util.alpha(Commons.Color.menu.text, 0.15)
              border.width: 1

              Text {
                anchors.centerIn: parent
                text: "Esc"
                font.family: Style.font.family
                font.pixelSize: 11
                font.bold: true
                color: Commons.Color.menu.text
              }
            }
          }
        }
      }
    }
  }
}
