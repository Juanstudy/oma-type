// core/Settings.js - Settings management and serialization for oma-type

var DEFAULT_SETTINGS = {
  soundTheme: "thock",
  mode: "quote",
  quoteLength: "short",
  duration: 15,
  wordCount: 25,
  language: "english",
  punctuation: false,
  numbers: false,
  soundVolume: 0.55,
  bgImageEnabled: false,
  bgImagePath: "",
  bgBlur: 0.04,
  bgDither: true,
  bgDitherIntensity: 1,
  bgColorLevels: 2,
  bgCellSize: 2,
  bgAdaptiveDim: 0.65,
  bgDim: 0.4,
  bgVignette: false,
  bgAdaptiveAccent: true
};

var VALID_SOUND_THEMES = ["thock", "cream", "topre", "clicky", "typewriter", "off"];
var VALID_MODES = ["quote", "time", "words"];
var VALID_QUOTE_LENGTHS = ["short", "medium"];
var VALID_DURATIONS = [15, 30, 60];
var VALID_WORD_COUNTS = [10, 25, 50, 100];
var VALID_LANGUAGES = ["english", "spanish"];

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
    if (VALID_WORD_COUNTS.indexOf(parsed.wordCount) !== -1) {
      s.wordCount = parsed.wordCount;
    }
    if (VALID_LANGUAGES.indexOf(parsed.language) !== -1) {
      s.language = parsed.language;
    }
    if (typeof parsed.punctuation === "boolean") {
      s.punctuation = parsed.punctuation;
    }
    if (typeof parsed.numbers === "boolean") {
      s.numbers = parsed.numbers;
    }
    if (typeof parsed.soundVolume === "number" && parsed.soundVolume >= 0.0 && parsed.soundVolume <= 1.0) {
      s.soundVolume = parsed.soundVolume;
    }
    if (typeof parsed.bgImageEnabled === "boolean") {
      s.bgImageEnabled = parsed.bgImageEnabled;
    }
    if (typeof parsed.bgImagePath === "string") {
      s.bgImagePath = parsed.bgImagePath;
    }
    if (typeof parsed.bgBlur === "number" && parsed.bgBlur >= 0.0 && parsed.bgBlur <= 1.0) {
      s.bgBlur = parsed.bgBlur;
    }
    if (typeof parsed.bgDither === "boolean") {
      s.bgDither = parsed.bgDither;
    }
    if (typeof parsed.bgDitherIntensity === "number" && parsed.bgDitherIntensity >= 0.0 && parsed.bgDitherIntensity <= 1.0) {
      s.bgDitherIntensity = parsed.bgDitherIntensity;
    }
    if (typeof parsed.bgColorLevels === "number" && parsed.bgColorLevels >= 2 && parsed.bgColorLevels <= 64) {
      s.bgColorLevels = Math.round(parsed.bgColorLevels);
    }
    if (typeof parsed.bgCellSize === "number" && parsed.bgCellSize >= 1 && parsed.bgCellSize <= 6) {
      s.bgCellSize = Math.round(parsed.bgCellSize);
    }
    if (typeof parsed.bgAdaptiveDim === "number" && parsed.bgAdaptiveDim >= 0.0 && parsed.bgAdaptiveDim <= 1.0) {
      s.bgAdaptiveDim = parsed.bgAdaptiveDim;
    }
    if (typeof parsed.bgDim === "number" && parsed.bgDim >= 0.0 && parsed.bgDim <= 1.0) {
      s.bgDim = parsed.bgDim;
    }
    if (typeof parsed.bgVignette === "boolean") {
      s.bgVignette = parsed.bgVignette;
    }
    if (typeof parsed.bgAdaptiveAccent === "boolean") {
      s.bgAdaptiveAccent = parsed.bgAdaptiveAccent;
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
    VALID_SOUND_THEMES: VALID_SOUND_THEMES,
    VALID_MODES: VALID_MODES,
    VALID_QUOTE_LENGTHS: VALID_QUOTE_LENGTHS,
    VALID_DURATIONS: VALID_DURATIONS,
    VALID_WORD_COUNTS: VALID_WORD_COUNTS,
    VALID_LANGUAGES: VALID_LANGUAGES,
    getDefaultSettings: getDefaultSettings,
    parseSettings: parseSettings,
    serializeSettings: serializeSettings
  };
}
