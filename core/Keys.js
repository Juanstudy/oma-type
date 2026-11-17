// core/Keys.js - Key classification helpers for input handling

var DEAD_KEY_FIRST = 0x01001250; // Qt::Key_Dead_Grave
var DEAD_KEY_LAST = 0x01001293;  // Qt::Key_Dead_Longsolidusoverlay

// True for Qt dead-key events (´ ` ¨ ^ ~ etc.). Dead keys compose into the
// NEXT key event, which carries the final accented character, so they must
// never be typed as literal input.
function isDeadKey(key) {
  return typeof key === "number" && key >= DEAD_KEY_FIRST && key <= DEAD_KEY_LAST;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    isDeadKey: isDeadKey,
    DEAD_KEY_FIRST: DEAD_KEY_FIRST,
    DEAD_KEY_LAST: DEAD_KEY_LAST
  };
}
