const test = require("node:test");
const assert = require("node:assert/strict");
const Palette = require("../core/Palette.js");

test("Palette: hexToRgb parses standard 6-digit and 3-digit hex colors", () => {
  assert.deepEqual(Palette.hexToRgb("#ff0000"), { r: 255, g: 0, b: 0 });
  assert.deepEqual(Palette.hexToRgb("#00ff00"), { r: 0, g: 255, b: 0 });
  assert.deepEqual(Palette.hexToRgb("#0000ff"), { r: 0, g: 0, b: 255 });
  assert.deepEqual(Palette.hexToRgb("ffffff"), { r: 255, g: 255, b: 255 });
  assert.deepEqual(Palette.hexToRgb("#f00"), { r: 255, g: 0, b: 0 });
  assert.equal(Palette.hexToRgb("invalid"), null);
  assert.equal(Palette.hexToRgb(""), null);
  assert.equal(Palette.hexToRgb(null), null);
});

test("Palette: rgbToHsl calculates accurate hue, saturation, lightness", () => {
  const red = Palette.rgbToHsl(255, 0, 0);
  assert.equal(Math.round(red.h), 0);
  assert.equal(red.s, 1);
  assert.equal(red.l, 0.5);

  const white = Palette.rgbToHsl(255, 255, 255);
  assert.equal(white.s, 0);
  assert.equal(white.l, 1);

  const black = Palette.rgbToHsl(0, 0, 0);
  assert.equal(black.s, 0);
  assert.equal(black.l, 0);
});

test("Palette: scoreColor rewards readable vibrant colors and penalizes dark or washed tones", () => {
  // Dark color
  const darkScore = Palette.scoreColor("#00090d", 0);
  assert.ok(darkScore < 0, "Dark color should be heavily penalized");

  // Near white color
  const whiteScore = Palette.scoreColor("#fff1f4", 15);
  assert.ok(whiteScore < 0, "Overly washed-out color should be penalized");

  // Vibrant warm peach (ideal dark UI accent)
  const peachScore = Palette.scoreColor("#ffbd9e", 10);
  assert.ok(peachScore > 3.0, "Vibrant peach should score high");
});

test("Palette: pickAccent selects harmonious warm peach for sunset wallpaper palette", () => {
  const sunsetColors = [
    "#00090d", "#c0828b", "#f9ad96", "#ffd6c4",
    "#a36c92", "#e090b1", "#fec0ff", "#EAECE8",
    "#575f61", "#e0929e", "#ffbd9e", "#ffceb8",
    "#bf7bab", "#ff9ec8", "#ffd0ff", "#fff1f4"
  ];

  const picked = Palette.pickAccent(sunsetColors);
  assert.equal(picked, "#ffbd9e", "Should select warm glowing peach");
});

test("Palette: pickAccent selects warm sunlight yellow for anime sky palette", () => {
  const skyColors = [
    "#090215", "#e19b90", "#fcd47c", "#fdeb7c",
    "#8870b2", "#bb88c4", "#b798e4", "#FEF0B8",
    "#6a686e", "#ffb8aa", "#ffe043", "#ffef00",
    "#af90e5", "#e6a9f5", "#ddb6ff", "#ffed88"
  ];

  const picked = Palette.pickAccent(skyColors);
  assert.equal(picked, "#fdeb7c", "Should select warm sunlight gold");
});

test("Palette: pickAccent returns null gracefully on empty or invalid input", () => {
  assert.equal(Palette.pickAccent([]), null);
  assert.equal(Palette.pickAccent(null), null);
  assert.equal(Palette.pickAccent(["not-a-color", "invalid"]), null);
});
