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
