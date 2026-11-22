// core/Keys.js - Key classification helpers for input handling

var DEAD_KEY_FIRST = 0x01001250; // Qt::Key_Dead_Grave
var DEAD_KEY_LAST = 0x01001293;  // Qt::Key_Dead_Longsolidusoverlay

// Dead key code -> accent character it produces
var DEAD_KEY_ACCENTS = {
  0x01001250: "`", // Grave
  0x01001251: "´", // Acute
  0x01001252: "^", // Circumflex
  0x01001253: "~", // Tilde
  0x01001257: "¨"  // Diaeresis
};

// Accent -> composable base letters. Covers Spanish needs (á é í ó ú ñ ü)
// plus the grave/circumflex families so other layouts degrade gracefully.
var ACCENT_TABLES = {
  "´": { a: "á", e: "é", i: "í", o: "ó", u: "ú" },
  "`": { a: "à", e: "è", i: "ì", o: "ò", u: "ù" },
  "¨": { a: "ä", e: "ë", i: "ï", o: "ö", u: "ü" },
  "~": { n: "ñ" },
  "^": { a: "â", e: "ê", i: "î", o: "ô", u: "û" }
};

// True for Qt dead-key events (´ ` ¨ ^ ~ etc.). Dead keys compose into the
// NEXT key event, which carries the final accented character, so they must
// never be typed as literal input.
function isDeadKey(key) {
  return typeof key === "number" && key >= DEAD_KEY_FIRST && key <= DEAD_KEY_LAST;
}

// Accent character ("´", "`", "~", "¨", "^") for a dead key event, or null.
function deadAccent(key) {
  if (typeof key !== "number") return null;
  return DEAD_KEY_ACCENTS[key] || null;
}

// Compose a pending accent with the next character typed. Returns the
// composed character or null when the pair has no composition (including an
// already-composed input, which must pass through untouched).
function composeAccent(accent, ch) {
  var table = accent ? ACCENT_TABLES[accent] : null;
  if (!table || typeof ch !== "string" || ch.length !== 1) return null;
  var lower = ch.toLowerCase();
  var composed = table[lower];
  if (!composed) return null;
  return ch === lower ? composed : composed.toUpperCase();
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    isDeadKey: isDeadKey,
    deadAccent: deadAccent,
    composeAccent: composeAccent,
    DEAD_KEY_FIRST: DEAD_KEY_FIRST,
    DEAD_KEY_LAST: DEAD_KEY_LAST
  };
}
