const { test } = require("node:test");
const assert = require("node:assert");
const Keys = require("../core/Keys.js");

test("Keys: isDeadKey detects the Qt 6 dead-key range", () => {
  // Official Qt 6 range: Key_Dead_Grave (0x01001250) .. Key_Dead_Longsolidusoverlay (0x01001293)
  assert.equal(Keys.isDeadKey(0x01001250), true);  // Dead_Grave
  assert.equal(Keys.isDeadKey(0x01001251), true);  // Dead_Acute (´)
  assert.equal(Keys.isDeadKey(0x01001253), true);  // Dead_Tilde (~)
  assert.equal(Keys.isDeadKey(0x01001257), true);  // Dead_Diaeresis (¨)
  assert.equal(Keys.isDeadKey(0x01001293), true);  // last dead key
});

test("Keys: isDeadKey rejects printable and control keys", () => {
  assert.equal(Keys.isDeadKey("a".charCodeAt(0)), false);
  assert.equal(Keys.isDeadKey("á".charCodeAt(0)), false);
  assert.equal(Keys.isDeadKey(0x01000000), false); // Escape
  assert.equal(Keys.isDeadKey(0x0100124f), false); // one below the range
  assert.equal(Keys.isDeadKey(0x01001294), false); // one above the range
  assert.equal(Keys.isDeadKey(undefined), false);
  assert.equal(Keys.isDeadKey(null), false);
});

test("Keys: deadAccent maps dead key codes to their accent character", () => {
  assert.equal(Keys.deadAccent(0x01001251), "´");  // Dead_Acute
  assert.equal(Keys.deadAccent(0x01001250), "`");  // Dead_Grave
  assert.equal(Keys.deadAccent(0x01001253), "~");  // Dead_Tilde
  assert.equal(Keys.deadAccent(0x01001257), "¨");  // Dead_Diaeresis
  assert.equal(Keys.deadAccent(0x01001252), "^");  // Dead_Circumflex
  assert.equal(Keys.deadAccent("a".charCodeAt(0)), null);
  assert.equal(Keys.deadAccent(undefined), null);
});

test("Keys: composeAccent composes base letters with pending accents", () => {
  assert.equal(Keys.composeAccent("´", "a"), "á");
  assert.equal(Keys.composeAccent("´", "e"), "é");
  assert.equal(Keys.composeAccent("´", "i"), "í");
  assert.equal(Keys.composeAccent("´", "o"), "ó");
  assert.equal(Keys.composeAccent("´", "u"), "ú");
  assert.equal(Keys.composeAccent("~", "n"), "ñ");
  assert.equal(Keys.composeAccent("¨", "u"), "ü");   // güe/güi
  assert.equal(Keys.composeAccent("`", "a"), "à");
  assert.equal(Keys.composeAccent("^", "e"), "ê");
});

test("Keys: composeAccent preserves case", () => {
  assert.equal(Keys.composeAccent("´", "A"), "Á");
  assert.equal(Keys.composeAccent("~", "N"), "Ñ");
});

test("Keys: composeAccent returns null for non-composable input", () => {
  assert.equal(Keys.composeAccent("´", "z"), null);   // no ´z
  assert.equal(Keys.composeAccent("´", "b"), null);
  assert.equal(Keys.composeAccent("~", "a"), null);   // no ã in spanish
  assert.equal(Keys.composeAccent("´", "á"), null);   // already composed (IM active env)
  assert.equal(Keys.composeAccent(null, "a"), null);
  assert.equal(Keys.composeAccent("´", ""), null);
  assert.equal(Keys.composeAccent("´", "ab"), null);
});
