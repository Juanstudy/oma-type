// core/Settings.js - Settings management and serialization for oma-type

var DEFAULT_SETTINGS = {
  soundTheme: "thock",
  mode: "quote",
  quoteLength: "short",
  duration: 15,
  soundVolume: 0.55
};

var VALID_SOUND_THEMES = ["thock", "clicky", "typewriter", "off"];
var VALID_MODES = ["quote", "time"];
var VALID_QUOTE_LENGTHS = ["short", "medium"];
var VALID_DURATIONS = [15, 30];

function getDefaultSettings() {
  return Object.assign({}, DEFAULT_SETTINGS);
}

function parseSettings(jsonText) {
  var s = getDefaultSettings();
  if (!jsonText || typeof jsonText !== "string") return s;

  try {
    var parsed = JSON.parse(jsonText);
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) return s;

    if (VALID_SOUND_THEMES.indexOf(parsed.soundTheme) !== -1) {
      s.soundTheme = parsed.soundTheme;
    }
    if (VALID_MODES.indexOf(parsed.mode) !== -1) {
      s.mode = parsed.mode;
    }
    if (VALID_QUOTE_LENGTHS.indexOf(parsed.quoteLength) !== -1) {
      s.quoteLength = parsed.quoteLength;
    }
    if (VALID_DURATIONS.indexOf(parsed.duration) !== -1) {
      s.duration = parsed.duration;
    }
    if (typeof parsed.soundVolume === "number" && parsed.soundVolume >= 0.0 && parsed.soundVolume <= 1.0) {
      s.soundVolume = parsed.soundVolume;
    }
  } catch (e) {
    return s;
  }
  return s;
}

function serializeSettings(settings) {
  var s = parseSettings(JSON.stringify(settings || {}));
  return JSON.stringify(s, null, 2);
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    DEFAULT_SETTINGS: DEFAULT_SETTINGS,
    getDefaultSettings: getDefaultSettings,
    parseSettings: parseSettings,
    serializeSettings: serializeSettings
  };
}
