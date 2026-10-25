const test = require("node:test");
const assert = require("node:assert/strict");
const Settings = require("../core/Settings.js");

test("Settings: getDefaultSettings returns safe default values", () => {
  const defaults = Settings.getDefaultSettings();
  assert.equal(defaults.soundTheme, "thock");
  assert.equal(defaults.mode, "quote");
  assert.equal(defaults.quoteLength, "short");
  assert.equal(defaults.duration, 15);
  assert.equal(defaults.soundVolume, 0.55);
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

  // Invalid values should fallback to defaults
  const invalid = Settings.parseSettings(JSON.stringify({
    soundTheme: "hacker_neon",
    mode: "unsupported_mode",
    duration: 999,
    soundVolume: 50.0
  }));

  assert.equal(invalid.soundTheme, "thock");
  assert.equal(invalid.mode, "quote");
  assert.equal(invalid.duration, 15);
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
