const test = require("node:test");
const assert = require("node:assert/strict");
const Settings = require("../core/Settings.js");

test("Settings: getDefaultSettings returns safe default values", () => {
  const defaults = Settings.getDefaultSettings();
  assert.equal(defaults.soundTheme, "thock");
  assert.equal(defaults.mode, "quote");
  assert.equal(defaults.quoteLength, "short");
  assert.equal(defaults.duration, 15);
  assert.equal(defaults.wordCount, 25);
  assert.equal(defaults.language, "english");
  assert.equal(defaults.punctuation, false);
  assert.equal(defaults.numbers, false);
  assert.equal(defaults.soundVolume, 0.55);
  assert.equal(defaults.bgImageEnabled, false);
  assert.equal(defaults.bgImagePath, "");
  assert.equal(defaults.bgBlur, 0.04);
  assert.equal(defaults.bgDither, true);
  assert.equal(defaults.bgDitherIntensity, 1);
  assert.equal(defaults.bgColorLevels, 2);
  assert.equal(defaults.bgCellSize, 2);
  assert.equal(defaults.bgAdaptiveDim, 0.65);
  assert.equal(defaults.bgDim, 0.4);
  assert.equal(defaults.bgVignette, false);
  assert.equal(defaults.bgAdaptiveAccent, true);
});

test("Settings: parseSettings handles empty or corrupted JSON gracefully", () => {
  const empty = Settings.parseSettings("");
  assert.equal(empty.soundTheme, "thock");

  const corrupt = Settings.parseSettings("{ invalid json !!");
  assert.equal(corrupt.soundTheme, "thock");
  assert.equal(corrupt.mode, "quote");

  const nonObject = Settings.parseSettings("[\"an\", \"array\"]");
  assert.equal(nonObject.mode, "quote");
});

test("Settings: parseSettings validates and sanitizes input properties", () => {
  const custom = Settings.parseSettings(JSON.stringify({
    soundTheme: "clicky",
    mode: "time",
    quoteLength: "medium",
    duration: 30,
    soundVolume: 0.8
  }));

  assert.equal(custom.soundTheme, "clicky");
  assert.equal(custom.mode, "time");
  assert.equal(custom.quoteLength, "medium");
  assert.equal(custom.duration, 30);
  assert.equal(custom.soundVolume, 0.8);

  // New settings support: 60s duration, words mode, wordCount, punctuation, numbers
  const wordsSettings = Settings.parseSettings(JSON.stringify({
    mode: "words",
    wordCount: 50,
    duration: 60,
    punctuation: true,
    numbers: true
  }));
  assert.equal(wordsSettings.mode, "words");
  assert.equal(wordsSettings.wordCount, 50);
  assert.equal(wordsSettings.duration, 60);
  assert.equal(wordsSettings.punctuation, true);
  assert.equal(wordsSettings.numbers, true);

  // New mechanical sound themes: cream and topre
  const creamSettings = Settings.parseSettings(JSON.stringify({ soundTheme: "cream" }));
  assert.equal(creamSettings.soundTheme, "cream");

  const topreSettings = Settings.parseSettings(JSON.stringify({ soundTheme: "topre" }));
  assert.equal(topreSettings.soundTheme, "topre");

  // Language settings: english and spanish
  const esSettings = Settings.parseSettings(JSON.stringify({ language: "spanish" }));
  assert.equal(esSettings.language, "spanish");

  const invalidLang = Settings.parseSettings(JSON.stringify({ language: "klingon" }));
  assert.equal(invalidLang.language, "english");

  // Background customization settings (dithering, blur, image)
  const bgCustom = Settings.parseSettings(JSON.stringify({
    bgImageEnabled: true,
    bgImagePath: "/home/user/wallpaper.jpg",
    bgBlur: 0.4,
    bgDither: false,
    bgDitherIntensity: 0.8,
    bgColorLevels: 8,
    bgCellSize: 4,
    bgAdaptiveDim: 0.9,
    bgDim: 0.75,
    bgVignette: false,
    bgAdaptiveAccent: false
  }));
  assert.equal(bgCustom.bgImageEnabled, true);
  assert.equal(bgCustom.bgImagePath, "/home/user/wallpaper.jpg");
  assert.equal(bgCustom.bgBlur, 0.4);
  assert.equal(bgCustom.bgDither, false);
  assert.equal(bgCustom.bgDitherIntensity, 0.8);
  assert.equal(bgCustom.bgColorLevels, 8);
  assert.equal(bgCustom.bgCellSize, 4);
  assert.equal(bgCustom.bgAdaptiveDim, 0.9);
  assert.equal(bgCustom.bgDim, 0.75);
  assert.equal(bgCustom.bgVignette, false);
  assert.equal(bgCustom.bgAdaptiveAccent, false);

  // Invalid values should fallback to defaults
  const invalid = Settings.parseSettings(JSON.stringify({
    soundTheme: "hacker_neon",
    mode: "unsupported_mode",
    duration: 999,
    wordCount: 333,
    punctuation: "not-a-bool",
    numbers: 123,
    soundVolume: 50.0
  }));

  assert.equal(invalid.soundTheme, "thock");
  assert.equal(invalid.mode, "quote");
  assert.equal(invalid.duration, 15);
  assert.equal(invalid.wordCount, 25);
  assert.equal(invalid.punctuation, false);
  assert.equal(invalid.numbers, false);
  assert.equal(invalid.soundVolume, 0.55);
});

test("Settings: serializeSettings produces clean indented JSON", () => {
  const serialized = Settings.serializeSettings({
    soundTheme: "typewriter",
    duration: 30
  });

  const parsed = JSON.parse(serialized);
  assert.equal(parsed.soundTheme, "typewriter");
  assert.equal(parsed.duration, 30);
  assert.equal(parsed.mode, "quote"); // default retained
});
