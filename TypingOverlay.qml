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
import "core/Keys.js" as KeysModule
import "components"

Item {
  id: root

  property bool opened: false
  property string activeView: "test" // "test" | "stats" | "settings"
  property string mode: "quote" // "quote" | "time" | "words"
  property string quoteLength: "short" // "short" | "medium"
  property int duration: 15 // 15, 30, or 60 seconds
  property int wordCount: 25 // 10, 25, 50, or 100 words
  property string language: "english" // "english" | "spanish"
  property bool punctuation: false
  property bool numbers: false
  property var session: null
  property var stats: ({ wpm: 0, rawWpm: 0, accuracy: 100, timeLeft: 15, elapsedSeconds: 0, isFinished: false, status: "idle", quote: null, totalKeypresses: 0 })
  property int sessionRevision: 0
  readonly property bool isTypingActive: root.activeView === "test" && root.stats.status === "running" && !root.stats.isFinished

  property string soundTheme: "thock" // "thock" | "clicky" | "typewriter" | "off"
  property double soundVolume: 0.55
  property bool bgImageEnabled: false
  property string bgImagePath: ""
  property double bgBlur: 0.04
  property bool bgDither: true
  property double bgDitherIntensity: 1

  property double bgColorLevels: 2
  property double bgCellSize: 2
  property double bgAdaptiveDim: 0.65

  property double bgDim: 0.4
  property bool bgVignette: false
  property bool bgAdaptiveAccent: true
  property string wallpaperAccentColor: ""
  readonly property color themeAccent: {
    if (root.bgImageEnabled && root.bgAdaptiveAccent && root.wallpaperAccentColor !== "") {
      return root.wallpaperAccentColor
    }
    return Commons.Color.menu.selectedText
  }
  property bool settingsLoaded: false
  property string pendingAccent: ""
  property bool focusPrimed: false
  property bool isMaximized: false
  property real cardCustomWidth: 1080
  property real cardCustomHeight: 640
  property real cardOffsetX: 0
  property real cardOffsetY: 0
  property bool isDraggingWindow: false
  property bool isResizingWindow: false
  property real windowScale: 1.0
  property real maximizedScale: 1.35
  readonly property real targetUiScale: root.isMaximized ? root.maximizedScale : root.windowScale
  property real uiScale: targetUiScale

  Behavior on uiScale {
    NumberAnimation {
      id: uiScaleAnim
      duration: 220
      easing.type: Easing.OutCubic
      onRunningChanged: {
        if (!running && root.opened) {
          Qt.callLater(root.updateCaretPosition)
        }
      }
    }
  }

  onUiScaleChanged: {
    if (root.opened) {
      Qt.callLater(root.updateCaretPosition)
    }
  }

  function scaled(val) {
    return Math.round(val * root.uiScale)
  }

  function toggleMaximize() {
    root.isMaximized = !root.isMaximized
    root.showToast(root.isMaximized ? "Focus Mode: On" : "Focus Mode: Off")
    Qt.callLater(function() {
      root.updateCaretPosition()
      keyCatcher.forceActiveFocus()
    })
  }

  function resetWindowPosition() {
    root.isMaximized = false
    root.cardCustomWidth = 1080
    root.cardCustomHeight = 640
    root.cardOffsetX = 0
    root.cardOffsetY = 0
  }
  // Resolve relative to this QML file (repo root) so the plugin works through
  // the omarchy plugins symlink without a hardcoded home path. Must stay a raw
  // filesystem path: the consumer is pw-play, not an Audio element.
  property string soundBaseDir: {
    var override = Quickshell.env("OMA_TYPE_SOUNDS_DIR")
    if (override && override.trim() !== "") return override.trim()
    var url = Qt.resolvedUrl("assets/sounds").toString()
    return url.indexOf("file://") === 0 ? decodeURIComponent(url.substring(7)) : url
  }
  property string extractAccentScript: {
    var override = Quickshell.env("OMA_TYPE_EXTRACT_ACCENT")
    if (override && override.trim() !== "") return override.trim()
    var url = Qt.resolvedUrl("bin/extract-accent").toString()
    return url.indexOf("file://") === 0 ? decodeURIComponent(url.substring(7)) : url
  }
  property double lastSoundTime: 0

  property var history: []
  property var summary: ({ totalTests: 0, bestWpm: 0, avgWpm: 0, avgAccuracy: 0, totalSeconds: 0 })
  property bool recordedCurrent: false

  // Dismiss Omarchy's "Launching Typing Practice..." feedback OSD.
  // Because oma-type is a LayerShell overlay and not an XDG toplevel,
  // omarchy's AppLibrary waits 15s for a toplevel window to appear before
  // dismissing the OSD. This timer intercepts and closes it promptly.
  Timer {
    id: osdDismissTimer
    interval: 200
    repeat: true
    property int attempts: 0
    onTriggered: {
      attempts++
      Quickshell.execDetached(["omarchy-shell", "osd", "close"])
      if (attempts >= 14) stop()
    }
  }

  function open() {
    root.opened = true
    root.focusPrimed = false
    focusPrimeTimer.restart()
    osdDismissTimer.attempts = 0
    osdDismissTimer.restart()
    root.activeView = "test"
    root.isMaximized = false
    root.cardCustomWidth = 1080
    root.cardCustomHeight = 640
    root.cardOffsetX = 0
    root.cardOffsetY = 0
    root.resetTest()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() {
    focusPrimeTimer.stop()
    root.focusPrimed = false
    root.opened = false
    root.isMaximized = false
    root.cardCustomWidth = 1080
    root.cardCustomHeight = 640
    root.cardOffsetX = 0
    root.cardOffsetY = 0
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

  function setWordCount(count) {
    root.wordCount = count
    root.resetTest()
    root.saveSettings()
  }

  function toggleWordCount() {
    var counts = [10, 25, 50, 100]
    var idx = (counts.indexOf(root.wordCount) + 1) % counts.length
    root.setWordCount(counts[idx])
  }

  function toggleQuoteLength() {
    root.quoteLength = (root.quoteLength === "short") ? "medium" : "short"
    root.resetTest()
    root.saveSettings()
  }

  function toggleDuration() {
    var durations = [15, 30, 60]
    var idx = (durations.indexOf(root.duration) + 1) % durations.length
    root.setDuration(durations[idx])
  }

  function toggleMode() {
    root.activeView = "test"
    if (root.mode === "time") root.setMode("words")
    else if (root.mode === "words") root.setMode("quote")
    else root.setMode("time")
  }

  function toggleLengthOrDuration() {
    root.activeView = "test"
    if (root.mode === "quote") {
      root.toggleQuoteLength()
    } else if (root.mode === "words") {
      root.toggleWordCount()
    } else {
      root.toggleDuration()
    }
  }

  function togglePunctuation() {
    root.punctuation = !root.punctuation
    root.resetTest()
    root.saveSettings()
  }

  function toggleNumbers() {
    root.numbers = !root.numbers
    root.resetTest()
    root.saveSettings()
  }

  function setLanguage(lang) {
    if (root.language === lang) return
    root.language = lang
    root.resetTest()
    root.saveSettings()
    root.showToast(root.language === "spanish" ? "Idioma: Español" : "Language: English")
  }

  function toggleLanguage() {
    root.setLanguage(root.language === "spanish" ? "english" : "spanish")
  }

  function toggleStatsView() {
    root.activeView = (root.activeView === "stats") ? "test" : "stats"
    if (root.activeView === "stats") {
      root.summary = HistoryModule.getSummary(root.history)
      graphAnim.restart()
    }
  }

  property string toastMessage: ""
  property bool toastVisible: false

  Timer {
    id: toastTimer
    interval: 1200
    repeat: false
    onTriggered: { root.toastVisible = false }
  }

  function showToast(msg) {
    root.toastMessage = msg
    root.toastVisible = true
    toastTimer.restart()
  }

  function adjustVolume(delta) {
    var newVol = Math.round((root.soundVolume + delta) * 20) / 20
    newVol = Math.max(0.0, Math.min(1.0, newVol))
    root.soundVolume = newVol
    root.saveSettings()

    // Acoustic feedback
    root.lastSoundTime = 0
    root.playKeySound()

    var pct = Math.round(root.soundVolume * 100)
    root.showToast("Volume: " + pct + "%")
  }

  function cycleSoundTheme() {
    var themes = ["thock", "cream", "topre", "clicky", "typewriter", "off"]
    var nextIdx = (themes.indexOf(root.soundTheme) + 1) % themes.length
    root.soundTheme = themes[nextIdx]
    root.lastSoundTime = 0
    root.playKeySound()
    root.saveSettings()
    root.showToast(root.soundTheme === "off" ? "Sound: Off" : "Switch: " + root.soundTheme)
  }

  function loadSettings(jsonText) {
    var s = SettingsModule.parseSettings(jsonText)
    root.soundTheme = s.soundTheme
    root.mode = s.mode
    root.quoteLength = s.quoteLength
    root.duration = s.duration
    root.wordCount = s.wordCount
    root.language = s.language || "english"
    root.punctuation = s.punctuation
    root.numbers = s.numbers
    root.soundVolume = s.soundVolume
    root.bgImageEnabled = s.bgImageEnabled
    root.bgImagePath = s.bgImagePath
    root.bgBlur = s.bgBlur
    root.bgDither = s.bgDither
    root.bgDitherIntensity = s.bgDitherIntensity
    root.bgColorLevels = s.bgColorLevels
    root.bgCellSize = s.bgCellSize
    root.bgAdaptiveDim = s.bgAdaptiveDim
    root.bgDim = s.bgDim
    root.bgVignette = (s.bgVignette !== undefined) ? s.bgVignette : false
    root.bgAdaptiveAccent = (s.bgAdaptiveAccent !== undefined) ? s.bgAdaptiveAccent : true
    root.settingsLoaded = true
    root.resetTest()
    root.updateWallpaperAccent()
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
      wordCount: root.wordCount,
      language: root.language,
      punctuation: root.punctuation,
      numbers: root.numbers,
      soundVolume: root.soundVolume,
      bgImageEnabled: root.bgImageEnabled,
      bgImagePath: root.bgImagePath,
      bgBlur: root.bgBlur,
      bgDither: root.bgDither,
      bgDitherIntensity: root.bgDitherIntensity,
      bgColorLevels: root.bgColorLevels,
      bgCellSize: root.bgCellSize,
      bgAdaptiveDim: root.bgAdaptiveDim,
      bgDim: root.bgDim,
      bgVignette: root.bgVignette,
      bgAdaptiveAccent: root.bgAdaptiveAccent
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
    } else if (root.soundTheme === "cream") {
      file = root.soundBaseDir + "/cream/" + (Math.floor(Math.random() * 4) + 1) + ".wav"
    } else if (root.soundTheme === "topre") {
      file = root.soundBaseDir + "/topre/" + (Math.floor(Math.random() * 4) + 1) + ".wav"
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
    root.pendingAccent = ""
    if (keyCatcher) keyCatcher.text = ""
    root.recordedCurrent = false
    root.sessionRevision = 0
    if (wordsFlickable) wordsFlickable.contentY = 0

    if (root.mode === "time") {
      var wordList = WordsModule.getRandomWords(80, { language: root.language, punctuation: root.punctuation, numbers: root.numbers })
      root.session = EngineModule.createSession({ mode: "time", duration: root.duration, words: wordList })
    } else if (root.mode === "words") {
      var wordList = WordsModule.getRandomWords(root.wordCount, { language: root.language, punctuation: root.punctuation, numbers: root.numbers })
      root.session = EngineModule.createSession({ mode: "words", words: wordList })
    } else {
      var lastQuoteId = root.session && root.session.quote ? root.session.quote.id : null
      var q = QuotesModule.getRandomQuote(root.quoteLength, lastQuoteId, root.language)
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
    var caretBottom = wItem.y + root.scaled(44)
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

  Process {
    id: paletteProcess
    command: []
    stdout: StdioCollector {
      id: paletteOut
      waitForEnd: true
      onStreamFinished: {
        var col = String(paletteOut.text || "").trim()
        if (col && /^#[0-9a-fA-F]{6}$/.test(col)) {
          root.wallpaperAccentColor = col
        }
      }
    }
  }

  function updateWallpaperAccent() {
    if (!root.bgImageEnabled || !root.bgAdaptiveAccent) {
      root.wallpaperAccentColor = ""
      return
    }
    var imgPath = root.bgImagePath
    if (!imgPath || imgPath.trim() === "") {
      imgPath = (Quickshell.env("HOME") || "") + "/.local/state/omarchy/current/background"
    }
    if (paletteProcess.running) {
      paletteProcess.running = false
    }
    paletteProcess.command = [root.extractAccentScript, imgPath]
    paletteProcess.running = true
  }

  onBgImagePathChanged: root.updateWallpaperAccent()
  onBgImageEnabledChanged: root.updateWallpaperAccent()
  onBgAdaptiveAccentChanged: root.updateWallpaperAccent()

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

    function toggleFocus(): string {
      root.toggleMaximize()
      return root.isMaximized ? "maximized" : "restored"
    }

    function resetPosition(): string {
      root.resetWindowPosition()
      return "ok"
    }

    function setScale(val: string): string {
      var s = parseFloat(val)
      if (!isNaN(s) && s >= 0.8 && s <= 2.5) {
        if (root.isMaximized) {
          root.maximizedScale = s
        } else {
          root.windowScale = s
        }
        root.showToast("Scale: " + Math.round(s * 100) + "%")
        Qt.callLater(root.updateCaretPosition)
        return "ok: " + s
      }
      return "invalid: " + val
    }

    function getScale(): string {
      return String(root.uiScale)
    }

    function reset(): string {
      root.resetTest()
      return "ok"
    }

    function ping(): string {
      return "ok"
    }

    function setBackground(path: string): string {
      root.bgImagePath = path
      root.bgImageEnabled = true
      root.saveSettings()
      root.showToast("Background set")
      return "ok"
    }

    function toggleBackground(): string {
      root.bgImageEnabled = !root.bgImageEnabled
      root.saveSettings()
      root.showToast(root.bgImageEnabled ? "Background: On" : "Background: Off")
      return root.bgImageEnabled ? "on" : "off"
    }

    function toggleDither(): string {
      root.bgDither = !root.bgDither
      root.saveSettings()
      root.showToast(root.bgDither ? "Dither: On" : "Dither: Off")
      return root.bgDither ? "on" : "off"
    }

    function toggleVignette(): string {
      root.bgVignette = !root.bgVignette
      root.saveSettings()
      root.showToast(root.bgVignette ? "Vignette: On" : "Vignette: Off")
      return root.bgVignette ? "on" : "off"
    }

    function toggleAdaptiveAccent(): string {
      root.bgAdaptiveAccent = !root.bgAdaptiveAccent
      root.saveSettings()
      root.showToast(root.bgAdaptiveAccent ? "Adaptive Accent: On" : "Adaptive Accent: Off")
      return root.bgAdaptiveAccent ? "on" : "off"
    }
  }

  Timer {
    id: focusPrimeTimer
    interval: 75
    onTriggered: if (root.opened) root.focusPrimed = true
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "oma-type"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.opened
      ? (root.focusPrimed ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive)
      : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    onVisibleChanged: {
      if (visible) {
        root.focusPrimed = false
        focusPrimeTimer.restart()
        Qt.callLater(function() { keyCatcher.forceActiveFocus() })
      } else {
        focusPrimeTimer.stop()
        root.focusPrimed = false
      }
    }

    Item {
      id: overlayContainer
      anchors.fill: parent

      // Scrim backdrop with smooth fade-in
      Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.opened ? (root.isMaximized ? 0.0 : 0.72) : 0.0

        Behavior on opacity {
          NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }

        MouseArea {
          anchors.fill: parent
          enabled: !root.isMaximized
          onClicked: root.close()
        }
      }

      // Centered card (Scaled 1.25x: 1080×640, Resizable, or Fullscreen Focus Mode)
      BorderSurface {
        id: card
        width: root.isMaximized ? overlayContainer.width : Math.min(root.cardCustomWidth, overlayContainer.width - Style.space(32))
        height: root.isMaximized ? overlayContainer.height : Math.min(root.cardCustomHeight, overlayContainer.height - Style.space(32))

        x: root.isMaximized ? 0 : Math.round(Math.max(16, Math.min(overlayContainer.width - width - 16, (overlayContainer.width - width) / 2 + root.cardOffsetX)))
        y: root.isMaximized ? 0 : Math.round(Math.max(16, Math.min(overlayContainer.height - height - 16, (overlayContainer.height - height) / 2 + root.cardOffsetY)))

        property real cardOffsetX: root.cardOffsetX
        property real cardOffsetY: root.cardOffsetY

        radius: root.isMaximized ? 0 : Math.max(Style.cornerRadius, 14)
        color: Commons.Color.menu.background
        borderSpec: Border.surfaceSpec("menu", "border", Commons.Color.menu.border, root.isMaximized ? 0 : 1)
        clip: true

        Behavior on x {
          enabled: !root.isDraggingWindow && !root.isResizingWindow
          NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on y {
          enabled: !root.isDraggingWindow && !root.isResizingWindow
          NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on width {
          enabled: !root.isResizingWindow
          NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on height {
          enabled: !root.isResizingWindow
          NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on radius {
          NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        onWidthChanged: {
          if (root.opened) {
            Qt.callLater(root.updateCaretPosition)
          }
        }

        ResizeHandles {
          id: resizeHandles
          targetCard: card
          overlay: overlayContainer
          enabled: !root.isMaximized
          onResizingChanged: root.isResizingWindow = resizing
          onUpdateDimensions: function(newW, newH, newOffX, newOffY) {
            root.cardCustomWidth = newW
            root.cardCustomHeight = newH
            root.cardOffsetX = newOffX
            root.cardOffsetY = newOffY
          }
          onResizeCommitted: {
            Qt.callLater(function() {
              root.updateCaretPosition()
              keyCatcher.forceActiveFocus()
            })
          }
        }

      DitheredBackground {
        anchors.fill: parent
        bgEnabled: root.bgImageEnabled
        imagePath: root.bgImagePath
        blurAmount: root.bgBlur
        ditherEnabled: root.bgDither
        ditherIntensity: root.bgDitherIntensity
        colorLevels: root.bgColorLevels
        cellSize: root.bgCellSize
        adaptiveDim: root.bgAdaptiveDim
        dimOpacity: root.bgDim
        dimColor: Commons.Color.menu.background
        radius: card.radius
        vignetteEnabled: root.bgVignette
      }

      opacity: root.opened ? 1.0 : 0.0
      scale: root.opened ? 1.0 : 0.96

      Behavior on opacity {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
      }
      Behavior on scale {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
      }

      focus: true
      Keys.forwardTo: [keyCatcher]
      Keys.onEscapePressed: function(event) {
        root.pendingAccent = ""
        if (root.activeView === "settings" || root.activeView === "stats") {
          root.activeView = "test"
        } else {
          root.close()
        }
        event.accepted = true
      }

      MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: keyCatcher.forceActiveFocus()
      }

      TextInput {
        id: keyCatcher
        x: 0
        y: 0
        width: 1
        height: 1
        opacity: 0
        focus: true
        clip: true
        color: "transparent"
        cursorVisible: false
        cursorDelegate: Item {}
        selectByMouse: false

        onActiveFocusChanged: {
          if (!activeFocus && root.opened && root.activeView !== "settings") {
            Qt.callLater(function() {
              if (root.opened && root.activeView !== "settings") {
                keyCatcher.forceActiveFocus()
              }
            })
          }
        }

        // Receive composed characters from Input Methods (e.g. fcitx5 dead keys: ´ + o -> ó, ñ, ü)
        onTextEdited: {
          if (root.activeView !== "test" || root.stats.isFinished) {
            text = ""
            return
          }
          if (text.length > 0) {
            var committed = text
            text = ""
            for (var i = 0; i < committed.length; i++) {
              var ch = committed.charAt(i)
              if (ch.charCodeAt(0) >= 32) {
                root.playKeySound()
                EngineModule.handleKey(root.session, ch, Date.now())
                root.sessionRevision++
                root.updateStats()
                root.updateCaretPosition()
              }
            }
          }
        }

        Keys.priority: Keys.BeforeItem

        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            root.pendingAccent = ""
            if (root.activeView === "settings") {
              root.activeView = "test"
              event.accepted = true
              return
            }
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
            root.pendingAccent = ""
            root.activeView = "test"
            root.resetTest()
            event.accepted = true
            return
          }

          // Shortcuts: F-keys and Ctrl combinations
          var isCtrl = (event.modifiers & Qt.ControlModifier)

          // Ctrl+Comma: Toggle Settings panel
          if (isCtrl && event.key === Qt.Key_Comma) {
            root.activeView = (root.activeView === "settings") ? "test" : "settings"
            event.accepted = true
            return
          }

          // F11 or Ctrl+Shift+M: Toggle Focus / Maximized Mode
          if (event.key === Qt.Key_F11 || (isCtrl && (event.modifiers & Qt.ShiftModifier) && event.key === Qt.Key_M)) {
            root.toggleMaximize()
            event.accepted = true
            return
          }

          // F1 or Ctrl+M: Toggle Mode (Quote <-> Time)
          if (event.key === Qt.Key_F1 || (isCtrl && event.key === Qt.Key_M)) {
            root.toggleMode()
            event.accepted = true
            return
          }

          // Ctrl+B: Toggle Background Image
          if (isCtrl && event.key === Qt.Key_B) {
            root.bgImageEnabled = !root.bgImageEnabled
            root.saveSettings()
            root.showToast(root.bgImageEnabled ? "Background: On" : "Background: Off")
            event.accepted = true
            return
          }

          // Ctrl+D: Toggle Dithering Effect
          if (isCtrl && event.key === Qt.Key_D) {
            root.bgDither = !root.bgDither
            root.saveSettings()
            root.showToast(root.bgDither ? "Dither: On" : "Dither: Off")
            event.accepted = true
            return
          }

          // Ctrl+V: Toggle Perimeter Vignette Effect
          if (isCtrl && event.key === Qt.Key_V) {
            root.bgVignette = !root.bgVignette
            root.saveSettings()
            root.showToast(root.bgVignette ? "Vignette: On" : "Vignette: Off")
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

          // Ctrl+P: Toggle punctuation
          if (isCtrl && event.key === Qt.Key_P) {
            root.togglePunctuation()
            event.accepted = true
            return
          }

          // Ctrl+N: Toggle numbers
          if (isCtrl && event.key === Qt.Key_N) {
            root.toggleNumbers()
            event.accepted = true
            return
          }

          // Ctrl+I: Toggle language (English <-> Spanish)
          if (isCtrl && event.key === Qt.Key_I) {
            root.toggleLanguage()
            event.accepted = true
            return
          }

          // Ctrl+Up: Increase volume
          if (isCtrl && event.key === Qt.Key_Up) {
            root.adjustVolume(0.05)
            event.accepted = true
            return
          }

          // Ctrl+Down: Decrease volume
          if (isCtrl && event.key === Qt.Key_Down) {
            root.adjustVolume(-0.05)
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

          // Settings view swallows everything so typing never reaches the
          // test handler while the panel is open (shortcuts above still work)
          if (root.activeView === "settings") return

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

          // Dead keys (´ ` ¨ ^ ~) fallback: if an environment does not route
          // input methods (no fcitx/ibus), stash the accent and compose locally.
          if (KeysModule.isDeadKey(event.key)) {
            root.pendingAccent = KeysModule.deadAccent(event.key) || ""
            event.accepted = true
            return
          }

          var keyStr = ""
          if (event.key === Qt.Key_Backspace) {
            root.pendingAccent = ""
            keyStr = "Backspace"
            event.accepted = true
          } else if (event.key === Qt.Key_Space) {
            root.pendingAccent = ""
            keyStr = " "
            event.accepted = true
          } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32) {
            keyStr = event.text
            if (root.pendingAccent !== "") {
              var composed = KeysModule.composeAccent(root.pendingAccent, event.text)
              if (composed) keyStr = composed
              root.pendingAccent = ""
            }
          }

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

      // Floating HUD Toast (Volume & Switch changes)
      Rectangle {
        id: hudToast
        anchors.top: parent.top
        anchors.topMargin: root.scaled(16)
        anchors.horizontalCenter: parent.horizontalCenter
        height: root.scaled(32)
        width: toastText.contentWidth + root.scaled(26)
        radius: root.scaled(16)
        color: Commons.Color.menu.selectedBackground
        opacity: root.toastVisible ? 1.0 : 0.0
        visible: opacity > 0.01
        z: 200

        Behavior on opacity {
          NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        OutlinedText {
          id: toastText
          anchors.centerIn: parent
          text: root.toastMessage
          font.family: Style.font.family
          font.pixelSize: root.scaled(12)
          font.bold: true
          color: root.themeAccent
        }
      }

      // Header Dithered Scrim (Bayer ordered dissolve for ambient contrast)
      DitheredScrim {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.scaled(115)
        direction: 0.0
        cellSize: root.bgCellSize
        ditherIntensity: root.bgDither ? 1.0 : 0.0
        color: Commons.Color.menu.background
        maxAlpha: root.bgImageEnabled ? 0.96 : 0.0
        minAlpha: 0.0
        solidSpan: 0.45
        opacity: header.opacity
        visible: root.bgImageEnabled
      }

      // ---------------------------------------------------- Header (Scaled 1.25x)
      Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.scaled(64)
        anchors.leftMargin: root.scaled(24)
        anchors.rightMargin: root.scaled(24)
        opacity: (root.isTypingActive && !headerDragArea.containsMouse) ? 0.0 : 1.0

        Behavior on opacity {
          NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
        }

        MouseArea {
          id: headerDragArea
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton
          cursorShape: root.isMaximized ? Qt.ArrowCursor : (root.isDraggingWindow ? Qt.ClosedHandCursor : Qt.OpenHandCursor)

          property real startGlobalX: 0
          property real startGlobalY: 0
          property real startOffsetX: 0
          property real startOffsetY: 0

          onPressed: function(mouse) {
            if (root.isMaximized || !overlayContainer) return
            var p = mapToItem(overlayContainer, mouse.x, mouse.y)
            startGlobalX = p.x
            startGlobalY = p.y
            startOffsetX = root.cardOffsetX
            startOffsetY = root.cardOffsetY
            root.isDraggingWindow = true
          }

          onPositionChanged: function(mouse) {
            if (!root.isDraggingWindow || root.isMaximized || !overlayContainer) return
            var p = mapToItem(overlayContainer, mouse.x, mouse.y)
            var dx = p.x - startGlobalX
            var dy = p.y - startGlobalY

            var maxOffsetX = Math.max(0, (overlayContainer.width - card.width) / 2 - 16)
            var maxOffsetY = Math.max(0, (overlayContainer.height - card.height) / 2 - 16)

            root.cardOffsetX = Math.max(-maxOffsetX, Math.min(maxOffsetX, startOffsetX + dx))
            root.cardOffsetY = Math.max(-maxOffsetY, Math.min(maxOffsetY, startOffsetY + dy))
          }

          onReleased: function() {
            root.isDraggingWindow = false
            Qt.callLater(function() { keyCatcher.forceActiveFocus() })
          }

          onCanceled: function() {
            root.isDraggingWindow = false
            Qt.callLater(function() { keyCatcher.forceActiveFocus() })
          }

          onDoubleClicked: function() {
            root.toggleMaximize()
          }
        }

        // Top-Left: Back button
        Rectangle {
          id: backBtn
          width: root.scaled(36)
          height: root.scaled(36)
          radius: root.scaled(8)
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          color: backMouse.containsMouse
            ? Util.alpha(Commons.Color.menu.background, 0.95)
            : (root.bgImageEnabled ? Util.alpha(Commons.Color.menu.background, 0.8) : Util.alpha(Commons.Color.menu.text, 0.04))
          border.color: Util.alpha(Commons.Color.menu.text, 0.18)
          border.width: 1

          OutlinedText {
            anchors.centerIn: parent
            text: "←"
            font.pixelSize: root.scaled(18)
            color: Util.alpha(Commons.Color.menu.text, 0.7)
          }

          MouseArea {
            id: backMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (root.activeView === "stats" || root.activeView === "settings") root.activeView = "test"
              else root.close()
            }
          }
        }

        // Top-Center: Compact Unified Mode & Stats Pill (Raycast style)
        Row {
          id: topCenterRow
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          spacing: root.scaled(8)

          // Compact Unified Mode Pill
          Rectangle {
            id: modePill
            height: root.scaled(34)
            width: modePillContent.width + root.scaled(24)
            radius: root.scaled(8)
            color: modeMouse.containsMouse
              ? Util.alpha(Commons.Color.menu.background, 0.95)
              : (root.bgImageEnabled ? Util.alpha(Commons.Color.menu.background, 0.82) : Util.alpha(Commons.Color.menu.text, 0.04))
            border.color: modeMouse.containsMouse
              ? Util.alpha(root.themeAccent, 0.4)
              : Util.alpha(Commons.Color.menu.text, 0.2)
            border.width: 1

            Row {
              id: modePillContent
              anchors.centerIn: parent
              spacing: root.scaled(8)

              // Mode name
              OutlinedText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.mode === "time" ? "Time" : (root.mode === "words" ? "Words" : "Quote")
                font.family: Style.font.family
                font.pixelSize: root.scaled(13)
                font.bold: true
                color: Commons.Color.menu.text
              }

              // Divider dot
              OutlinedText {
                anchors.verticalCenter: parent.verticalCenter
                text: "·"
                font.family: Style.font.family
                font.pixelSize: root.scaled(12)
                color: Util.alpha(Commons.Color.menu.text, 0.3)
              }

              // Active option (15s / 25w / short)
              OutlinedText {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                  if (root.mode === "time") return root.duration + "s ▾"
                  if (root.mode === "words") return root.wordCount + "w ▾"
                  return root.quoteLength + " ▾"
                }
                font.family: Style.font.family
                font.pixelSize: root.scaled(12)
                color: root.themeAccent
              }

              // Language toggle chip (ES / EN)
              Rectangle {
                visible: root.mode !== "quote"
                height: root.scaled(20)
                width: langLabel.contentWidth + root.scaled(10)
                radius: root.scaled(4)
                anchors.verticalCenter: parent.verticalCenter
                color: root.language === "spanish" ? Util.alpha(root.themeAccent, 0.2) : "transparent"
                border.color: root.language === "spanish" ? Util.alpha(root.themeAccent, 0.4) : Util.alpha(Commons.Color.menu.text, 0.15)
                border.width: 1

                OutlinedText {
                  id: langLabel
                  anchors.centerIn: parent
                  text: root.language === "spanish" ? "ES" : "EN"
                  font.family: Style.font.family
                  font.pixelSize: root.scaled(10)
                  font.bold: true
                  color: root.language === "spanish" ? root.themeAccent : Util.alpha(Commons.Color.menu.text, 0.45)
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.toggleLanguage()
                }
              }

              // Punctuation toggle chip
              Rectangle {
                height: root.scaled(20)
                width: puncLabel.contentWidth + root.scaled(10)
                radius: root.scaled(4)
                anchors.verticalCenter: parent.verticalCenter
                color: root.punctuation ? Util.alpha(root.themeAccent, 0.2) : "transparent"
                border.color: root.punctuation ? Util.alpha(root.themeAccent, 0.4) : "transparent"
                border.width: 1

                OutlinedText {
                  id: puncLabel
                  anchors.centerIn: parent
                  text: "@ punc"
                  font.family: Style.font.family
                  font.pixelSize: root.scaled(10)
                  font.bold: root.punctuation
                  color: root.punctuation ? root.themeAccent : Util.alpha(Commons.Color.menu.text, 0.35)
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.togglePunctuation()
                }
              }

              // Numbers toggle chip
              Rectangle {
                height: root.scaled(20)
                width: numLabel.contentWidth + root.scaled(10)
                radius: root.scaled(4)
                anchors.verticalCenter: parent.verticalCenter
                color: root.numbers ? Util.alpha(root.themeAccent, 0.2) : "transparent"
                border.color: root.numbers ? Util.alpha(root.themeAccent, 0.4) : "transparent"
                border.width: 1

                OutlinedText {
                  id: numLabel
                  anchors.centerIn: parent
                  text: "# 123"
                  font.family: Style.font.family
                  font.pixelSize: root.scaled(10)
                  font.bold: root.numbers
                  color: root.numbers ? root.themeAccent : Util.alpha(Commons.Color.menu.text, 0.35)
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.toggleNumbers()
                }
              }
            }

            MouseArea {
              id: modeMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton || mouse.x > parent.width * 0.48) {
                  root.toggleLengthOrDuration()
                } else {
                  root.toggleMode()
                }
              }
            }
          }

          // Stats Pill Button
          Rectangle {
            id: statsPillBtn
            height: root.scaled(34)
            width: statsPillText.contentWidth + root.scaled(20)
            radius: root.scaled(8)
            color: root.activeView === "stats"
              ? Commons.Color.menu.selectedBackground
              : (statsMouse.containsMouse ? Util.alpha(Commons.Color.menu.background, 0.95) : (root.bgImageEnabled ? Util.alpha(Commons.Color.menu.background, 0.82) : Util.alpha(Commons.Color.menu.text, 0.04)))
            border.color: root.activeView === "stats" ? Util.alpha(root.themeAccent, 0.5) : Util.alpha(Commons.Color.menu.text, 0.2)
            border.width: 1

            OutlinedText {
              id: statsPillText
              anchors.centerIn: parent
              text: "Stats"
              font.family: Style.font.family
              font.pixelSize: root.scaled(12)
              font.bold: root.activeView === "stats"
              color: root.activeView === "stats" ? root.themeAccent : Util.alpha(Commons.Color.menu.text, 0.6)
            }

            MouseArea {
              id: statsMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.toggleStatsView()
            }
          }
        }

        // Top-Right: Sound switch & Live metrics
        Row {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: root.scaled(16)

          OutlinedText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.soundTheme === "off" ? "sound: off" : root.soundTheme
            font.family: Style.font.family
            font.pixelSize: root.scaled(13)
            color: root.soundTheme !== "off" ? Util.alpha(Commons.Color.menu.text, 0.5) : Util.alpha(Commons.Color.menu.text, 0.25)
            Behavior on color { ColorAnimation { duration: 100 } }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.cycleSoundTheme()
            }
          }

          // Live Timer / Stopwatch (Test View)
          OutlinedText {
            visible: root.activeView === "test"
            anchors.verticalCenter: parent.verticalCenter
            text: root.mode === "time"
              ? root.stats.timeLeft + "s"
              : (root.stats.status === "idle" ? "0.0s" : root.stats.elapsedSeconds + "s")
            font.family: Style.font.family
            font.pixelSize: root.scaled(18)
            font.bold: true
            color: (root.mode === "time" && root.stats.timeLeft <= 3) ? "#e06c75" : root.themeAccent
          }

          OutlinedText {
            visible: root.activeView === "test"
            anchors.verticalCenter: parent.verticalCenter
            text: root.stats.wpm + " wpm"
            font.family: Style.font.family
            font.pixelSize: root.scaled(13)
            color: Util.alpha(Commons.Color.menu.text, 0.4)
          }

          OutlinedText {
            visible: root.activeView === "test"
            anchors.verticalCenter: parent.verticalCenter
            text: root.stats.accuracy + "%"
            font.family: Style.font.family
            font.pixelSize: root.scaled(13)
            color: Util.alpha(Commons.Color.menu.text, 0.4)
          }

          Rectangle {
            width: 1
            height: root.scaled(14)
            anchors.verticalCenter: parent.verticalCenter
            color: Util.alpha(Commons.Color.menu.text, 0.12)
          }

          // Maximize / Focus mode button (⤢ / ⤡)
          Rectangle {
            id: maximizeBtn
            width: root.scaled(28)
            height: root.scaled(28)
            radius: root.scaled(6)
            anchors.verticalCenter: parent.verticalCenter
            color: maximizeMouse.containsMouse
              ? Util.alpha(Commons.Color.menu.background, 0.95)
              : (root.isMaximized
                  ? Util.alpha(root.themeAccent, 0.2)
                  : (root.bgImageEnabled ? Util.alpha(Commons.Color.menu.background, 0.75) : "transparent"))
            border.color: root.isMaximized ? root.themeAccent : Util.alpha(Commons.Color.menu.text, 0.18)
            border.width: 1

            OutlinedText {
              anchors.centerIn: parent
              text: root.isMaximized ? "⤡" : "⤢"
              font.family: Style.font.family
              font.pixelSize: root.scaled(13)
              font.bold: true
              color: (maximizeMouse.containsMouse || root.isMaximized) ? root.themeAccent : Util.alpha(Commons.Color.menu.text, 0.5)
            }

            MouseArea {
              id: maximizeMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.toggleMaximize()
                keyCatcher.forceActiveFocus()
              }
            }
          }

          // Close button (✕)
          Rectangle {
            id: closeBtn
            width: root.scaled(28)
            height: root.scaled(28)
            radius: root.scaled(6)
            anchors.verticalCenter: parent.verticalCenter
            color: closeMouse.containsMouse
              ? Util.alpha(Commons.Color.menu.background, 0.95)
              : (root.bgImageEnabled ? Util.alpha(Commons.Color.menu.background, 0.75) : "transparent")
            border.color: Util.alpha(Commons.Color.menu.text, 0.18)
            border.width: 1

            OutlinedText {
              anchors.centerIn: parent
              text: "✕"
              font.family: Style.font.family
              font.pixelSize: root.scaled(13)
              font.bold: true
              color: closeMouse.containsMouse ? root.themeAccent : Util.alpha(Commons.Color.menu.text, 0.5)
            }

            MouseArea {
              id: closeMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.close()
            }
          }
        }
      }

      // Hairline separator (hidden when wallpaper is active)
      Rectangle {
        id: sep
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        height: visible ? 1 : 0
        color: Util.alpha(Commons.Color.menu.text, 0.14)
        opacity: header.opacity
        visible: !(root.bgImageEnabled && root.bgImagePath !== "")
        Behavior on opacity {
          NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
        }
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

            // Frosted glass capsule (disabled in clean stealth wallpaper mode)
            Rectangle {
              id: typingCapsule
              anchors.fill: centeredTypingBox
              anchors.margins: -24
              anchors.topMargin: -18
              anchors.bottomMargin: -16
              radius: 18
              visible: false
              color: Commons.Color.menu.background
              opacity: 0.85
              border.color: Commons.Color.menu.border
              border.width: 1
              z: 0
            }

            Item {
              id: centeredTypingBox
              z: 1
              anchors.centerIn: parent
              width: Math.min(root.isMaximized ? 1240 : 960, parent.width)
              height: root.isMaximized ? Math.min(500, parent.height - 40) : Math.min(parent.height - 20, root.scaled(310))

              Behavior on width {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
              }
              Behavior on height {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
              }

              Flickable {
                id: wordsFlickable
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: quoteAuthorRow.top
                anchors.bottomMargin: root.scaled(20)
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
                    width: Math.max(3.5, root.scaled(3.2))
                    height: root.scaled(35)
                    radius: root.scaled(1.6)
                    color: root.themeAccent
                    visible: !root.stats.isFinished && root.session && root.session.status !== "finished"
                    z: 10

                    property real targetX: 0
                    property real targetY: 0
                    readonly property bool animateCaret: root.sessionRevision > 0

                    x: targetX
                    y: targetY

                    Behavior on x {
                      enabled: smoothCaret.animateCaret
                      NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                    }
                    Behavior on y {
                      enabled: smoothCaret.animateCaret
                      NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                    }
                  }

                  Flow {
                    id: flowContainer
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: root.scaled(16)

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

                            OutlinedText {
                              id: charText
                              text: charBox.cData ? charBox.cData.char : ""
                              font.family: Style.font.family
                              font.pixelSize: root.scaled(30)
                              color: {
                                root.sessionRevision
                                if (!charBox.cData) return Util.alpha(Commons.Color.menu.text, 0.60)
                                if (charBox.cData.state === "correct") return "#ffffff"
                                if (charBox.cData.state === "incorrect") return "#ff5555"
                                return Util.alpha(Commons.Color.menu.text, 0.60)
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

                          delegate: OutlinedText {
                            text: {
                              root.sessionRevision
                              return (wData && wData.extra) ? wData.extra[index] : ""
                            }
                            font.family: Style.font.family
                            font.pixelSize: root.scaled(30)
                            font.bold: true
                            color: "#e06c75"
                          }
                        }

                        // Trailing space
                        Item {
                          id: spaceBox
                          width: spaceText.contentWidth
                          height: spaceText.contentHeight

                          OutlinedText {
                            id: spaceText
                            text: " "
                            font.family: Style.font.family
                            font.pixelSize: root.scaled(30)
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
                height: root.scaled(26)
                visible: root.mode === "quote" && root.session && root.session.quote

                OutlinedText {
                  text: root.session && root.session.quote ? "— " + root.session.quote.source : ""
                  font.family: Style.font.family
                  font.pixelSize: root.scaled(14)
                  font.italic: true
                  color: Util.alpha(Commons.Color.menu.text, 0.55)
                }
              }
            }
          }

          // Test Finished Summary: MASSIVE 115px WPM
          Item {
            anchors.centerIn: parent
            width: finishedColumn.width + 64
            height: finishedColumn.height + 48
            visible: root.stats.isFinished

            Rectangle {
              anchors.fill: parent
              radius: 18
              visible: false
              color: Commons.Color.menu.background
              opacity: 0.85
              border.color: Commons.Color.menu.border
              border.width: 1
            }

            Column {
              id: finishedColumn
              anchors.centerIn: parent
              spacing: root.scaled(16)

            OutlinedText {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.stats.wpm
              font.family: Style.font.family
              font.pixelSize: root.scaled(115)
              font.bold: true
              color: root.themeAccent
            }

            OutlinedText {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "WORDS PER MINUTE"
              font.family: Style.font.family
              font.pixelSize: root.scaled(13)
              font.bold: true
              color: Util.alpha(Commons.Color.menu.text, 0.4)
            }

            OutlinedText {
              anchors.horizontalCenter: parent.horizontalCenter
              visible: root.mode === "quote" && root.stats.quote
              text: root.stats.quote ? "— " + root.stats.quote.source : ""
              font.family: Style.font.family
              font.pixelSize: root.scaled(16)
              font.italic: true
              color: Util.alpha(Commons.Color.menu.text, 0.6)
            }

            Row {
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: root.scaled(32)
              anchors.topMargin: root.scaled(12)

              OutlinedText {
                text: root.stats.accuracy + "% accuracy"
                font.family: Style.font.family
                font.pixelSize: root.scaled(18)
                color: Commons.Color.menu.text
              }

              OutlinedText {
                text: "·"
                color: Util.alpha(Commons.Color.menu.text, 0.3)
              }

              OutlinedText {
                text: root.stats.elapsedSeconds + "s time"
                font.family: Style.font.family
                font.pixelSize: root.scaled(18)
                color: Commons.Color.menu.text
              }

              OutlinedText {
                text: "·"
                color: Util.alpha(Commons.Color.menu.text, 0.3)
              }

              OutlinedText {
                text: root.stats.rawWpm + " raw"
                font.family: Style.font.family
                font.pixelSize: root.scaled(18)
                color: Commons.Color.menu.text
              }
            }

            Item { width: 1; height: root.scaled(12) }

            OutlinedText {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "tab or enter to restart"
              font.family: Style.font.family
              font.pixelSize: root.scaled(13)
              color: Util.alpha(Commons.Color.menu.text, 0.35)
            }
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
            spacing: root.scaled(20)

            // 1. Pure Typography Metrics (34px)
            Row {
              width: parent.width

              Column {
                width: parent.width / 4
                spacing: root.scaled(3)
                OutlinedText {
                  text: root.summary.bestWpm > 0 ? String(root.summary.bestWpm) : "—"
                  font.family: Style.font.family
                  font.pixelSize: root.scaled(34)
                  font.bold: true
                  color: root.themeAccent
                }
                OutlinedText {
                  text: "best wpm"
                  font.family: Style.font.family
                  font.pixelSize: root.scaled(12)
                  color: Util.alpha(Commons.Color.menu.text, 0.4)
                }
              }

              Column {
                width: parent.width / 4
                spacing: root.scaled(3)
                OutlinedText {
                  text: root.summary.avgWpm > 0 ? String(root.summary.avgWpm) : "—"
                  font.family: Style.font.family
                  font.pixelSize: root.scaled(34)
                  font.bold: true
                  color: Commons.Color.menu.text
                }
                OutlinedText {
                  text: "avg wpm"
                  font.family: Style.font.family
                  font.pixelSize: root.scaled(12)
                  color: Util.alpha(Commons.Color.menu.text, 0.4)
                }
              }

              Column {
                width: parent.width / 4
                spacing: root.scaled(3)
                OutlinedText {
                  text: root.summary.avgAccuracy > 0 ? root.summary.avgAccuracy + "%" : "—"
                  font.family: Style.font.family
                  font.pixelSize: root.scaled(34)
                  font.bold: true
                  color: Commons.Color.menu.text
                }
                OutlinedText {
                  text: "accuracy"
                  font.family: Style.font.family
                  font.pixelSize: root.scaled(12)
                  color: Util.alpha(Commons.Color.menu.text, 0.4)
                }
              }

              Column {
                width: parent.width / 4
                spacing: root.scaled(3)
                OutlinedText {
                  text: String(root.summary.totalTests)
                  font.family: Style.font.family
                  font.pixelSize: root.scaled(34)
                  font.bold: true
                  color: Commons.Color.menu.text
                }
                OutlinedText {
                  text: "tests completed"
                  font.family: Style.font.family
                  font.pixelSize: root.scaled(12)
                  color: Util.alpha(Commons.Color.menu.text, 0.4)
                }
              }
            }

            // 2. Wireframe Chart (Height 175px)
            Item {
              width: parent.width
              height: root.scaled(175)

              OutlinedText {
                anchors.centerIn: parent
                visible: root.history.length < 2
                text: root.history.length === 0 ? "no test data yet" : "complete 1 more test to draw curve"
                font.family: Style.font.family
                font.pixelSize: root.scaled(13)
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
              spacing: root.scaled(8)

              OutlinedText {
                text: "recent"
                font.family: Style.font.family
                font.pixelSize: root.scaled(11)
                color: Util.alpha(Commons.Color.menu.text, 0.35)
              }

              Repeater {
                model: Math.min(3, root.history.length)

                delegate: Item {
                  width: statsViewContainer.width
                  height: root.scaled(26)

                  readonly property var hItem: root.history[index]

                  Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.scaled(20)

                    OutlinedText {
                      text: hItem.mode || "time"
                      font.family: Style.font.family
                      font.pixelSize: root.scaled(13)
                      color: Util.alpha(Commons.Color.menu.text, 0.4)
                      width: root.scaled(46)
                    }

                    OutlinedText {
                      text: hItem.wpm + " wpm"
                      font.family: Style.font.family
                      font.pixelSize: root.scaled(13)
                      font.bold: true
                      color: Commons.Color.menu.text
                      width: root.scaled(64)
                    }

                    OutlinedText {
                      text: hItem.accuracy + "%"
                      font.family: Style.font.family
                      font.pixelSize: root.scaled(13)
                      color: Util.alpha(Commons.Color.menu.text, 0.5)
                      width: root.scaled(44)
                    }

                    OutlinedText {
                      visible: hItem.quoteSource && hItem.quoteSource.length > 0
                      text: hItem.quoteSource
                      font.family: Style.font.family
                      font.pixelSize: root.scaled(13)
                      font.italic: true
                      color: Util.alpha(Commons.Color.menu.text, 0.3)
                      elide: Text.ElideRight
                      width: 420
                    }
                  }

                  OutlinedText {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: hItem.elapsedSeconds + "s"
                    font.family: Style.font.family
                    font.pixelSize: root.scaled(13)
                    color: Util.alpha(Commons.Color.menu.text, 0.3)
                  }
                }
              }
            }
          }
        }

        // =================================== VIEW 3: SETTINGS PANEL
        // Stateless: binds to root properties; writes go through
        // settingsChanged -> setters -> saveSettings
        SettingsPanel {
          id: settingsPanel
          open: root.activeView === "settings"
          mode: root.mode
          quoteLength: root.quoteLength
          duration: root.duration
          wordCount: root.wordCount
          language: root.language
          punctuation: root.punctuation
          numbers: root.numbers
          soundTheme: root.soundTheme
          soundVolume: root.soundVolume
          bgImageEnabled: root.bgImageEnabled
          bgImagePath: root.bgImagePath
          bgBlur: root.bgBlur
          bgDither: root.bgDither
          bgDitherIntensity: root.bgDitherIntensity
          bgColorLevels: root.bgColorLevels
          bgCellSize: root.bgCellSize
          bgDim: root.bgDim
          bgAdaptiveDim: root.bgAdaptiveDim
          bgVignette: root.bgVignette
          bgAdaptiveAccent: root.bgAdaptiveAccent
          themeAccent: root.themeAccent

          onSettingsChanged: function(key, value) {
            if (key === "mode") root.setMode(value)
            else if (key === "quoteLength") root.setQuoteLength(value)
            else if (key === "duration") root.setDuration(Number(value))
            else if (key === "wordCount") root.setWordCount(Number(value))
            else if (key === "language") root.setLanguage(value)
            else if (key === "punctuation") {
              if (root.punctuation !== value) {
                root.punctuation = value
                root.resetTest()
              }
            }
            else if (key === "numbers") {
              if (root.numbers !== value) {
                root.numbers = value
                root.resetTest()
              }
            }
            else if (key === "soundTheme") {
              root.soundTheme = value
              root.lastSoundTime = 0
              root.playKeySound()
            }
            else if (key === "soundVolume") root.soundVolume = value
            else if (key === "bgImageEnabled") {
              root.bgImageEnabled = value
              root.showToast(root.bgImageEnabled ? "Background: On" : "Background: Off")
            }
            else if (key === "bgImagePath") {
              root.bgImagePath = value
              if (value !== "") root.bgImageEnabled = true
              root.showToast("Background set")
            }
            else if (key === "bgBlur") root.bgBlur = value
            else if (key === "bgDither") {
              root.bgDither = value
              root.showToast(root.bgDither ? "Dither: On" : "Dither: Off")
            }
            else if (key === "bgDitherIntensity") root.bgDitherIntensity = value
            else if (key === "bgColorLevels") root.bgColorLevels = value
            else if (key === "bgCellSize") root.bgCellSize = value
            else if (key === "bgDim") root.bgDim = value
            else if (key === "bgAdaptiveDim") root.bgAdaptiveDim = value
            else if (key === "bgVignette") {
              root.bgVignette = value
              root.showToast(root.bgVignette ? "Vignette: On" : "Vignette: Off")
            }
            else if (key === "bgAdaptiveAccent") {
              root.bgAdaptiveAccent = value
              root.showToast(root.bgAdaptiveAccent ? "Adaptive Accent: On" : "Adaptive Accent: Off")
            }
          }
          onSettingsCommit: root.saveSettings()
          onCloseRequested: root.activeView = "test"
          onFocusReleased: keyCatcher.forceActiveFocus()
        }
      }

      // Footer Dithered Scrim (Bayer ordered dissolve for ambient contrast)
      DitheredScrim {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 90
        direction: 1.0
        cellSize: root.bgCellSize
        ditherIntensity: root.bgDither ? 1.0 : 0.0
        color: Commons.Color.menu.background
        maxAlpha: root.bgImageEnabled ? 0.96 : 0.0
        minAlpha: 0.0
        solidSpan: 0.45
        opacity: footer.opacity
        visible: root.bgImageEnabled
      }

      // ---------------------------------------------------- Footer (Scaled 1.25x)
      Rectangle {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.scaled(48)
        color: (root.bgImageEnabled && root.bgImagePath !== "") ? "transparent" : Util.alpha(Commons.Color.menu.text, 0.02)
        opacity: (root.isTypingActive && !footerHover.containsMouse) ? 0.0 : 1.0

        Behavior on opacity {
          NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
        }

        MouseArea {
          id: footerHover
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.NoButton
        }

        Rectangle {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          height: 1
          color: Util.alpha(Commons.Color.menu.text, 0.12)
          visible: !(root.bgImageEnabled && root.bgImagePath !== "")
        }

        // Left: Omarchy glyph + Branding + subtle shortcut hint
        Row {
          anchors.left: parent.left
          anchors.leftMargin: root.scaled(24)
          anchors.verticalCenter: parent.verticalCenter
          spacing: root.scaled(12)

          Rectangle {
            width: root.scaled(26)
            height: root.scaled(26)
            radius: root.scaled(6)
            color: Util.alpha(root.themeAccent, 0.12)
            border.color: Util.alpha(root.themeAccent, 0.35)
            border.width: 1
            anchors.verticalCenter: parent.verticalCenter

            OutlinedText {
              anchors.centerIn: parent
              text: ""
              font.family: "omarchy"
              font.pixelSize: root.scaled(14)
              color: root.themeAccent
            }
          }

          OutlinedText {
            anchors.verticalCenter: parent.verticalCenter
            text: "Typing Practice"
            font.family: Style.font.family
            font.pixelSize: root.scaled(14)
            font.bold: true
            color: Util.alpha(Commons.Color.menu.text, 0.75)
          }

          Rectangle {
            width: 1
            height: root.scaled(12)
            anchors.verticalCenter: parent.verticalCenter
            color: Util.alpha(Commons.Color.menu.text, 0.1)
          }

          OutlinedText {
            anchors.verticalCenter: parent.verticalCenter
            text: "F1 mode · F2 option · F3 sound · F4 stats · F11 focus · ^I lang · ^, settings"
            font.family: Style.font.family
            font.pixelSize: root.scaled(11)
            color: Util.alpha(Commons.Color.menu.text, 0.3)
          }
        }

        // Right: Key badges (Only essential control actions: Restart & Close)
        Row {
          anchors.right: parent.right
          anchors.rightMargin: root.scaled(24)
          anchors.verticalCenter: parent.verticalCenter
          spacing: root.scaled(14)

          // Restart Hint
          Item {
            anchors.verticalCenter: parent.verticalCenter
            width: restartHintRow.width
            height: root.scaled(26)

            Row {
              id: restartHintRow
              anchors.verticalCenter: parent.verticalCenter
              spacing: root.scaled(6)

              OutlinedText {
                anchors.verticalCenter: parent.verticalCenter
                text: "Restart"
                font.family: Style.font.family
                font.pixelSize: root.scaled(12)
                color: restartMouse.containsMouse ? root.themeAccent : Util.alpha(Commons.Color.menu.text, 0.5)
              }

              Rectangle {
                width: root.scaled(36)
                height: root.scaled(22)
                radius: root.scaled(5)
                color: restartMouse.containsMouse
                  ? Util.alpha(root.themeAccent, 0.22)
                  : (root.bgImageEnabled ? Util.alpha(Commons.Color.menu.background, 0.85) : Util.alpha(Commons.Color.menu.text, 0.08))
                border.color: restartMouse.containsMouse
                  ? root.themeAccent
                  : Util.alpha(Commons.Color.menu.text, 0.24)
                border.width: 1

                OutlinedText {
                  anchors.centerIn: parent
                  text: "Tab"
                  font.family: Style.font.family
                  font.pixelSize: root.scaled(11)
                  font.bold: true
                  color: Commons.Color.menu.text
                }
              }
            }

            MouseArea {
              id: restartMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.resetTest()
                Qt.callLater(function() { keyCatcher.forceActiveFocus() })
              }
            }
          }

          Rectangle {
            width: 1
            height: root.scaled(14)
            anchors.verticalCenter: parent.verticalCenter
            color: Util.alpha(Commons.Color.menu.text, 0.12)
          }

          // Close Hint
          Item {
            anchors.verticalCenter: parent.verticalCenter
            width: closeHintRow.width
            height: root.scaled(26)

            Row {
              id: closeHintRow
              anchors.verticalCenter: parent.verticalCenter
              spacing: root.scaled(6)

              OutlinedText {
                anchors.verticalCenter: parent.verticalCenter
                text: "Close"
                font.family: Style.font.family
                font.pixelSize: root.scaled(12)
                color: closeFooterMouse.containsMouse ? root.themeAccent : Util.alpha(Commons.Color.menu.text, 0.5)
              }

              Rectangle {
                width: root.scaled(36)
                height: root.scaled(22)
                radius: root.scaled(5)
                color: closeFooterMouse.containsMouse
                  ? Util.alpha(root.themeAccent, 0.22)
                  : (root.bgImageEnabled ? Util.alpha(Commons.Color.menu.background, 0.85) : Util.alpha(Commons.Color.menu.text, 0.08))
                border.color: closeFooterMouse.containsMouse
                  ? root.themeAccent
                  : Util.alpha(Commons.Color.menu.text, 0.24)
                border.width: 1

                OutlinedText {
                  anchors.centerIn: parent
                  text: "Esc"
                  font.family: Style.font.family
                  font.pixelSize: root.scaled(11)
                  font.bold: true
                  color: Commons.Color.menu.text
                }
              }
            }

            MouseArea {
              id: closeFooterMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.close()
            }
          }
        }
      }
    }
  }
}
}
