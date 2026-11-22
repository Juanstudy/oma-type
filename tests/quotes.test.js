const { test } = require("node:test");
const assert = require("node:assert");
const Quotes = require("../core/Quotes.js");

test("Quotes: language spanish returns a Spanish quote (namespaced id)", () => {
  const q = Quotes.getRandomQuote("short", null, "spanish");
  assert.ok(q.id >= 10000, "spanish quote id should be >= 10000, got " + q.id);
  // Spanish dataset has accents/ñ; english quotes should not match this sample heuristic
  assert.ok(/[áéíóúñ¿¡]/i.test(q.text) || q.source.length > 0);
});

test("Quotes: language english (and default) returns an English quote", () => {
  const q = Quotes.getRandomQuote("short", null, "english");
  assert.ok(q.id < 10000, "english quote id should be < 10000, got " + q.id);

  const def = Quotes.getRandomQuote("medium", null, undefined);
  assert.ok(def.id < 10000);
});

test("Quotes: length filter is respected within a language", () => {
  for (let i = 0; i < 20; i++) {
    const q = Quotes.getRandomQuote("medium", null, "spanish");
    assert.equal(q.length, "medium");
    assert.ok(q.text.length >= 101 && q.text.length <= 300);
  }
});

test("Quotes: avoidId skips the previous quote within the same language", () => {
  const pool = Quotes.QUOTES_ES.filter(q => q.length === "short");
  const current = pool[0];
  let sawDifferent = false;
  for (let i = 0; i < 30; i++) {
    const q = Quotes.getRandomQuote("short", current.id, "spanish");
    assert.notEqual(q.id, current.id);
    sawDifferent = sawDifferent || q.id !== current.id;
  }
  assert.ok(sawDifferent);
});

test("Quotes: unknown language falls back to english", () => {
  const q = Quotes.getRandomQuote("short", null, "klingon");
  assert.ok(q.id < 10000);
});
