const test = require("node:test");
const assert = require("node:assert/strict");
const Words = require("../core/Words.js");

test("Words: default getRandomWords produces pure lowercase words without punctuation or digits", () => {
  const words = Words.getRandomWords(50);
  assert.equal(words.length, 50);

  for (const w of words) {
    assert.match(w, /^[a-z]+$/i, `Word should be alphabetical: ${w}`);
    assert.doesNotMatch(w, /[0-9]/, `Word should not contain numbers: ${w}`);
    assert.doesNotMatch(w, /[.,?!;:"'-]/, `Word should not contain punctuation: ${w}`);
  }
});

test("Words: getRandomWords with punctuation: true adds capital letters and punctuation marks", () => {
  const words = Words.getRandomWords(60, { punctuation: true });
  assert.equal(words.length, 60);

  let hasCapital = false;
  let hasPunctuation = false;

  for (const w of words) {
    if (/[A-Z]/.test(w)) hasCapital = true;
    if (/[.,?!;:"'-]/.test(w)) hasPunctuation = true;
  }

  assert.equal(hasCapital, true, "Should contain at least one capitalized word");
  assert.equal(hasPunctuation, true, "Should contain at least one punctuation mark");
});

test("Words: getRandomWords with numbers: true intersperses numeric tokens", () => {
  const words = Words.getRandomWords(60, { numbers: true });
  assert.equal(words.length, 60);

  let numberCount = 0;
  for (const w of words) {
    if (/^[0-9]+$/.test(w)) numberCount++;
  }

  assert.ok(numberCount > 0, `Expected some number tokens, got ${numberCount}`);
});

test("Words: getRandomWords supports both punctuation and numbers simultaneously", () => {
  const words = Words.getRandomWords(80, { punctuation: true, numbers: true });
  assert.equal(words.length, 80);

  let hasNumber = false;
  let hasPunctuation = false;
  let hasCapital = false;

  for (const w of words) {
    if (/[0-9]/.test(w)) hasNumber = true;
    if (/[.,?!;:"'-]/.test(w)) hasPunctuation = true;
    if (/[A-Z]/.test(w)) hasCapital = true;
  }

  assert.equal(hasNumber, true);
  assert.equal(hasPunctuation, true);
  assert.equal(hasCapital, true);
});

test("Words: getRandomWords with language: 'spanish' produces authentic Spanish words with accents and ñ", () => {
  const words = Words.getRandomWords(100, { language: "spanish" });
  assert.equal(words.length, 100);

  // Over 100 random words in Spanish, we expect to find at least some accented chars or ñ
  let hasSpanishAccentOrEnye = false;
  for (const w of words) {
    if (/[áéíóúñÁÉÍÓÚÑ]/.test(w)) {
      hasSpanishAccentOrEnye = true;
      break;
    }
  }
  assert.equal(hasSpanishAccentOrEnye, true, "Spanish random words should contain accented characters or ñ");
  assert.ok(Array.isArray(Words.WORDS_ES) && Words.WORDS_ES.length >= 900, "WORDS_ES should be exposed and contain ~1k words");
});
