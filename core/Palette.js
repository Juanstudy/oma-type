// core/Palette.js - Palette analysis and adaptive accent selection for oma-type

function hexToRgb(hex) {
  if (!hex || typeof hex !== "string") return null;
  var clean = hex.trim().replace(/^#/, "");
  if (clean.length === 3) {
    clean = clean.split("").map(function(c) { return c + c; }).join("");
  }
  if (clean.length !== 6 || !/^[0-9a-fA-F]{6}$/.test(clean)) return null;
  var num = parseInt(clean, 16);
  return {
    r: (num >> 16) & 255,
    g: (num >> 8) & 255,
    b: num & 255
  };
}

function rgbToHsl(r, g, b) {
  r /= 255;
  g /= 255;
  b /= 255;
  var max = Math.max(r, g, b);
  var min = Math.min(r, g, b);
  var h = 0, s = 0, l = (max + min) / 2;

  if (max !== min) {
    var d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    switch (max) {
      case r: h = ((g - b) / d + (g < b ? 6 : 0)) / 6; break;
      case g: h = ((b - r) / d + 2) / 6; break;
      case b: h = ((r - g) / d + 4) / 6; break;
    }
  }
  return { h: h * 360, s: s, l: l };
}

function scoreColor(hex, index) {
  var rgb = hexToRgb(hex);
  if (!rgb) return -100;
  var hsl = rgbToHsl(rgb.r, rgb.g, rgb.b);

  // Heavily penalize dark/muddy or washed-out white tones
  if (hsl.l < 0.38 || hsl.l > 0.94) return -50;
  // Penalize near-monochrome grays
  if (hsl.s < 0.20) return -20;

  // Optimal lightness on dark translucent backgrounds is ~0.72 (bright and readable)
  var lDiff = Math.abs(hsl.l - 0.72);
  var lScore = 1.0 - (lDiff / 0.5);

  // Saturation boosts colorfulness and vibrancy
  var sScore = hsl.s;

  // ANSI/Base16 color slots: indices 1-6 (red, green, yellow, blue, magenta, cyan)
  // and 9-14 (bright variants) are intentional theme accents in Aether/terminal palettes.
  // Slots 0 (bg), 7/15 (light fg), 8 (bright black/gray) are neutrals.
  var isColorSlot = (typeof index === "number") && ((index >= 1 && index <= 6) || (index >= 9 && index <= 14));
  var slotBonus = isColorSlot ? 0.6 : 0;

  return (lScore * 1.5) + (sScore * 2.2) + slotBonus;
}

function pickAccent(colors) {
  if (!Array.isArray(colors) || colors.length === 0) return null;

  var scored = [];
  for (var i = 0; i < colors.length; i++) {
    var raw = colors[i];
    if (typeof raw !== "string") continue;
    var cleanHex = raw.trim();
    if (!cleanHex.startsWith("#")) cleanHex = "#" + cleanHex;
    if (!/^#[0-9a-fA-F]{6}$/.test(cleanHex)) continue;

    var score = scoreColor(cleanHex, i);
    scored.push({ hex: cleanHex.toLowerCase(), score: score, index: i });
  }

  if (scored.length === 0) return null;

  scored.sort(function(a, b) {
    return b.score - a.score;
  });

  return scored[0].hex;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    hexToRgb: hexToRgb,
    rgbToHsl: rgbToHsl,
    scoreColor: scoreColor,
    pickAccent: pickAccent
  };
}
